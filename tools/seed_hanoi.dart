// ignore_for_file: avoid_print
// Coffee Lover — one-off Hanoi seed script
//
// Calls Google Places Nearby Search across a grid of Hanoi lat/lng points,
// enriches each result with Place Details, and upserts to Supabase.shops.
//
// Run from the project root:
//   dart run tools/seed_hanoi.dart
//
// Required env (in .env at the project root):
//   GOOGLE_PLACES_API_KEY
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY   // NEVER ship this in the Flutter client
//
// Notes:
//   - Writes with the service role key bypass RLS — run locally only.
//   - Places Nearby Search returns at most 60 results per location (3 pages of 20).
//     We cover Hanoi with a grid of anchor points at ~1km radius to reduce dupes.
//   - After seeding, re-run tools/merge_curated.dart (future) to layer on the
//     curated_hanoi.json overrides.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// Hanoi grid: pick anchor points across key neighborhoods.
// Rough bounding box: 20.98..21.10 lat, 105.78..105.90 lng.
const _anchors = <_Anchor>[
  _Anchor('Hoan Kiem',   21.0285, 105.8542),
  _Anchor('Old Quarter', 21.0345, 105.8500),
  _Anchor('Ba Dinh',     21.0335, 105.8400),
  _Anchor('Tay Ho south',21.0500, 105.8200),
  _Anchor('Tay Ho north',21.0700, 105.8250),
  _Anchor('Cau Giay',    21.0310, 105.7980),
  _Anchor('Dong Da',     21.0100, 105.8300),
  _Anchor('Hai Ba Trung',21.0100, 105.8500),
  _Anchor('Long Bien',   21.0420, 105.8800),
];

const _radiusMeters = 1200;

Future<void> main() async {
  final env = _loadDotEnv(File('.env'));
  final placesKey = env['GOOGLE_PLACES_API_KEY']!;
  final supabaseUrl = env['SUPABASE_URL']!;
  final serviceKey = env['SUPABASE_SERVICE_ROLE_KEY']!;

  final client = http.Client();
  final seenPlaceIds = <String>{};
  final shops = <Map<String, dynamic>>[];

  try {
    for (final a in _anchors) {
      stdout.write('Scanning ${a.label} … ');
      final results = await _nearbyAll(client, placesKey, a);
      var added = 0;
      for (final r in results) {
        final placeId = r['place_id'] as String?;
        if (placeId == null || !seenPlaceIds.add(placeId)) continue;
        final details = await _placeDetails(client, placesKey, placeId);
        shops.add(_toShopRow(details));
        added++;
      }
      print('$added new (total ${shops.length})');
    }

    print('\nUpserting ${shops.length} shops to Supabase …');
    await _upsertShops(client, supabaseUrl, serviceKey, shops);
    print('Done.');
  } finally {
    client.close();
  }
}

Future<List<Map<String, dynamic>>> _nearbyAll(
    http.Client client, String apiKey, _Anchor a) async {
  final all = <Map<String, dynamic>>[];
  String? pageToken;
  for (var page = 0; page < 3; page++) {
    final params = {
      'location': '${a.lat},${a.lng}',
      'radius': '$_radiusMeters',
      'type': 'cafe',
      'key': apiKey,
      if (pageToken != null) 'pagetoken': pageToken,
    };
    final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json')
        .replace(queryParameters: params);

    // Google requires a short wait before a page token becomes valid.
    if (pageToken != null) await Future.delayed(const Duration(seconds: 2));

    final res = await client.get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final status = body['status'] as String;
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('nearbysearch failed: $status ${body['error_message']}');
    }
    all.addAll((body['results'] as List).cast<Map<String, dynamic>>());
    pageToken = body['next_page_token'] as String?;
    if (pageToken == null) break;
  }
  return all;
}

Future<Map<String, dynamic>> _placeDetails(
    http.Client client, String apiKey, String placeId) async {
  final uri = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json')
      .replace(queryParameters: {
    'place_id': placeId,
    'fields':
        'place_id,name,geometry,formatted_address,formatted_phone_number,'
            'opening_hours,price_level,rating,photos',
    'key': apiKey,
  });
  final res = await client.get(uri);
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  if (body['status'] != 'OK') {
    throw Exception('details failed for $placeId: ${body['status']}');
  }
  return body['result'] as Map<String, dynamic>;
}

Map<String, dynamic> _toShopRow(Map<String, dynamic> d) {
  final loc = (d['geometry'] as Map)['location'] as Map;
  final photos = (d['photos'] as List?) ?? const [];
  return {
    'google_place_id': d['place_id'],
    'name': d['name'],
    'lat': (loc['lat'] as num).toDouble(),
    'lng': (loc['lng'] as num).toDouble(),
    'address': d['formatted_address'],
    'phone': d['formatted_phone_number'],
    'price_level': d['price_level'],
    'google_rating': d['rating'],
    'hours': d['opening_hours'],
    'photo_refs': photos
        .map((p) => (p as Map)['photo_reference'] as String)
        .toList(),
    'source': 'places',
    'is_curated': false,
  };
}

Future<void> _upsertShops(http.Client client, String supabaseUrl,
    String serviceKey, List<Map<String, dynamic>> shops) async {
  if (shops.isEmpty) return;
  final uri = Uri.parse('$supabaseUrl/rest/v1/shops?on_conflict=google_place_id');
  final res = await client.post(
    uri,
    headers: {
      'apikey': serviceKey,
      'Authorization': 'Bearer $serviceKey',
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates,return=minimal',
    },
    body: jsonEncode(shops),
  );
  if (res.statusCode >= 300) {
    throw Exception('Supabase upsert failed ${res.statusCode}: ${res.body}');
  }
}

Map<String, String> _loadDotEnv(File file) {
  if (!file.existsSync()) {
    throw StateError('.env not found at ${file.path} — copy .env.example');
  }
  final env = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    env[trimmed.substring(0, eq).trim()] =
        trimmed.substring(eq + 1).trim().replaceAll(RegExp('^"|"\$'), '');
  }
  for (final k in [
    'GOOGLE_PLACES_API_KEY',
    'SUPABASE_URL',
    'SUPABASE_SERVICE_ROLE_KEY',
  ]) {
    if ((env[k] ?? '').isEmpty) {
      throw StateError('Missing $k in .env');
    }
  }
  return env;
}

class _Anchor {
  final String label;
  final double lat;
  final double lng;
  const _Anchor(this.label, this.lat, this.lng);
}
