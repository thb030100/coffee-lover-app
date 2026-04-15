import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/env.dart';

/// Thin wrapper around the Google Places Web Service API.
/// Used by the seed script and for on-demand photo URL resolution.
/// Do NOT call Nearby Search from the client at runtime — the seed script
/// populates Supabase and the client reads from there.
class PlacesService {
  static const _base = 'https://maps.googleapis.com/maps/api/place';

  final http.Client _http;
  PlacesService({http.Client? client}) : _http = client ?? http.Client();

  /// Search for cafés around a lat/lng within [radiusMeters].
  /// Returns the raw `results` array from Places API.
  Future<List<Map<String, dynamic>>> nearbyCafes({
    required double lat,
    required double lng,
    int radiusMeters = 1000,
    String? pageToken,
  }) async {
    final params = {
      'location': '$lat,$lng',
      'radius': '$radiusMeters',
      'type': 'cafe',
      'key': Env.googlePlacesApiKey,
      if (pageToken != null) 'pagetoken': pageToken,
    };
    final uri = Uri.parse('$_base/nearbysearch/json')
        .replace(queryParameters: params);
    final res = await _http.get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    _assertOk(body, 'nearbysearch');
    return (body['results'] as List).cast<Map<String, dynamic>>();
  }

  /// Fetch rich details for a single place by its Google place_id.
  Future<Map<String, dynamic>> placeDetails(String placeId) async {
    final params = {
      'place_id': placeId,
      'fields':
          'place_id,name,geometry,formatted_address,formatted_phone_number,'
              'opening_hours,price_level,rating,photos',
      'key': Env.googlePlacesApiKey,
    };
    final uri = Uri.parse('$_base/details/json')
        .replace(queryParameters: params);
    final res = await _http.get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    _assertOk(body, 'details');
    return body['result'] as Map<String, dynamic>;
  }

  /// Resolve a Places photo_reference to a usable image URL.
  /// Returns the URL; the actual image is served by Google on GET.
  String photoUrl(String photoReference, {int maxWidth = 800}) {
    final qs = Uri(queryParameters: {
      'photo_reference': photoReference,
      'maxwidth': '$maxWidth',
      'key': Env.googlePlacesApiKey,
    }).query;
    return '$_base/photo?$qs';
  }

  void _assertOk(Map<String, dynamic> body, String op) {
    final status = body['status'] as String?;
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Places $op failed: $status ${body['error_message'] ?? ''}');
    }
  }

  void dispose() => _http.close();
}
