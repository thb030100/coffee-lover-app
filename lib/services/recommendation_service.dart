import 'dart:math';

import '../models/shop.dart';
import 'shop_repository.dart';

class UserPreferences {
  final int? priceMax;         // 1..4
  final double maxDistanceKm;
  final Set<String> preferredTags;

  const UserPreferences({
    this.priceMax,
    this.maxDistanceKm = 3.0,
    this.preferredTags = const {},
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      priceMax: json['price_max'] as int?,
      maxDistanceKm: (json['max_distance_km'] as num?)?.toDouble() ?? 3.0,
      preferredTags:
          ((json['preferred_tags'] as List?)?.cast<String>() ?? const [])
              .toSet(),
    );
  }

  Map<String, dynamic> toJson() => {
        'price_max': priceMax,
        'max_distance_km': maxDistanceKm,
        'preferred_tags': preferredTags.toList(),
      };
}

class _ShopWithDistance {
  final Shop shop;
  final double distanceKm;
  _ShopWithDistance(this.shop, this.distanceKm);
}

/// Filter + shuffle recommendation for the MVP.
/// Post-MVP: swap in content-scoring (weighted tag overlap + distance decay)
/// or collaborative filtering once swipe volume is meaningful.
class RecommendationService {
  RecommendationService(this._repo, {Random? rng})
      : _rng = rng ?? Random();

  final ShopRepository _repo;
  final Random _rng;

  Future<List<Shop>> getDeck({
    required String userId,
    required double userLat,
    required double userLng,
    required UserPreferences prefs,
    int limit = 20,
  }) async {
    final shops = await _repo.fetchAllShops();
    final recentlySwiped = await _repo.recentlySwipedShopIds(userId);

    final candidates = <_ShopWithDistance>[];
    for (final shop in shops) {
      if (recentlySwiped.contains(shop.id)) continue;
      if (prefs.priceMax != null &&
          shop.priceLevel != null &&
          shop.priceLevel! > prefs.priceMax!) {
        continue;
      }
      final distance = _haversineKm(userLat, userLng, shop.lat, shop.lng);
      if (distance > prefs.maxDistanceKm) continue;
      candidates.add(_ShopWithDistance(shop, distance));
    }

    candidates.shuffle(_rng);
    _injectPromoted(candidates, shops);

    return candidates.take(limit).map((c) => c.shop).toList();
  }

  /// Promoted shops (future partner portal) are sprinkled ~1 in 15.
  /// Safe no-op today since no shops have is_promoted=true.
  void _injectPromoted(List<_ShopWithDistance> deck, List<Shop> all) {
    final now = DateTime.now().toUtc();
    final promoted = all
        .where((s) =>
            s.isPromoted &&
            (s.promotedUntil == null || s.promotedUntil!.isAfter(now)))
        .toList();
    if (promoted.isEmpty) return;
    for (var i = 2; i < deck.length; i += 15) {
      final p = promoted[_rng.nextInt(promoted.length)];
      deck.insert(i, _ShopWithDistance(p, 0));
    }
  }
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthR = 6371.0;
  final dLat = _deg(lat2 - lat1);
  final dLng = _deg(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg(lat1)) * cos(_deg(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return earthR * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _deg(double d) => d * pi / 180.0;
