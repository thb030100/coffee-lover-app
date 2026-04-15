import 'dart:convert';

enum ShopSource { places, curatedManual, curatedIg, partner }

ShopSource _parseSource(String? raw) {
  switch (raw) {
    case 'curated_manual':
      return ShopSource.curatedManual;
    case 'curated_ig':
      return ShopSource.curatedIg;
    case 'partner':
      return ShopSource.partner;
    case 'places':
    default:
      return ShopSource.places;
  }
}

String _sourceToDb(ShopSource s) {
  switch (s) {
    case ShopSource.curatedManual:
      return 'curated_manual';
    case ShopSource.curatedIg:
      return 'curated_ig';
    case ShopSource.partner:
      return 'partner';
    case ShopSource.places:
      return 'places';
  }
}

class Shop {
  final String id;
  final String? googlePlaceId;
  final String name;
  final String? nameVi;
  final double lat;
  final double lng;
  final String? address;
  final int? priceLevel;
  final double? googleRating;
  final List<String> tags;
  final List<String> photoRefs;
  final List<String> photoUrls;
  final Map<String, dynamic>? hours;
  final String? phone;
  final ShopSource source;
  final String? sourceUrl;
  final bool isCurated;
  final bool isPromoted;
  final DateTime? promotedUntil;

  const Shop({
    required this.id,
    this.googlePlaceId,
    required this.name,
    this.nameVi,
    required this.lat,
    required this.lng,
    this.address,
    this.priceLevel,
    this.googleRating,
    this.tags = const [],
    this.photoRefs = const [],
    this.photoUrls = const [],
    this.hours,
    this.phone,
    this.source = ShopSource.places,
    this.sourceUrl,
    this.isCurated = false,
    this.isPromoted = false,
    this.promotedUntil,
  });

  String get displayName => (nameVi?.isNotEmpty ?? false) ? nameVi! : name;

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      googlePlaceId: json['google_place_id'] as String?,
      name: json['name'] as String,
      nameVi: json['name_vi'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String?,
      priceLevel: json['price_level'] as int?,
      googleRating: (json['google_rating'] as num?)?.toDouble(),
      tags: _stringList(json['tags']),
      photoRefs: _stringList(json['photo_refs']),
      photoUrls: _stringList(json['photo_urls']),
      hours: _maybeMap(json['hours']),
      phone: json['phone'] as String?,
      source: _parseSource(json['source'] as String?),
      sourceUrl: json['source_url'] as String?,
      isCurated: json['is_curated'] as bool? ?? false,
      isPromoted: json['is_promoted'] as bool? ?? false,
      promotedUntil: json['promoted_until'] == null
          ? null
          : DateTime.parse(json['promoted_until'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'google_place_id': googlePlaceId,
        'name': name,
        'name_vi': nameVi,
        'lat': lat,
        'lng': lng,
        'address': address,
        'price_level': priceLevel,
        'google_rating': googleRating,
        'tags': tags,
        'photo_refs': photoRefs,
        'photo_urls': photoUrls,
        'hours': hours,
        'phone': phone,
        'source': _sourceToDb(source),
        'source_url': sourceUrl,
        'is_curated': isCurated,
        'is_promoted': isPromoted,
        'promoted_until': promotedUntil?.toIso8601String(),
      };
}

List<String> _stringList(dynamic v) {
  if (v == null) return const [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}

Map<String, dynamic>? _maybeMap(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is String) return jsonDecode(v) as Map<String, dynamic>;
  return null;
}
