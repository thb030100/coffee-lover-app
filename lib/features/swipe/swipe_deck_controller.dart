import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/providers.dart';
import '../../models/shop.dart';
import '../../models/swipe.dart';
import '../../services/recommendation_service.dart' show UserPreferences;

class DeckState {
  final bool loading;
  final String? error;
  final List<Shop> shops;
  final double? userLat;
  final double? userLng;

  const DeckState({
    this.loading = false,
    this.error,
    this.shops = const [],
    this.userLat,
    this.userLng,
  });

  DeckState copyWith({
    bool? loading,
    String? error,
    List<Shop>? shops,
    double? userLat,
    double? userLng,
  }) =>
      DeckState(
        loading: loading ?? this.loading,
        error: error,
        shops: shops ?? this.shops,
        userLat: userLat ?? this.userLat,
        userLng: userLng ?? this.userLng,
      );
}

class DeckController extends StateNotifier<DeckState> {
  DeckController(this._ref) : super(const DeckState()) {
    load();
  }

  final Ref _ref;

  // Hanoi fallback center if location permission denied.
  static const _fallbackLat = 21.0285;
  static const _fallbackLng = 105.8542;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final (lat, lng) = await _resolveLocation();
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        state = state.copyWith(loading: false, error: 'Not signed in');
        return;
      }
      final prefs =
          await _ref.read(shopRepositoryProvider).fetchPreferences(user.id) ??
              const UserPreferences(maxDistanceKm: 3.0);
      final shops =
          await _ref.read(recommendationServiceProvider).getDeck(
                userId: user.id,
                userLat: lat,
                userLng: lng,
                prefs: prefs,
              );
      state = DeckState(shops: shops, userLat: lat, userLng: lng);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<(double, double)> _resolveLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return (_fallbackLat, _fallbackLng);
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return (_fallbackLat, _fallbackLng);
      }
      final pos = await Geolocator.getCurrentPosition();
      return (pos.latitude, pos.longitude);
    } catch (_) {
      return (_fallbackLat, _fallbackLng);
    }
  }

  Future<void> recordSwipe(Shop shop, SwipeDirection dir) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    await _ref.read(shopRepositoryProvider).recordSwipe(
          userId: user.id,
          shopId: shop.id,
          direction: dir,
        );
  }
}

final deckControllerProvider =
    StateNotifierProvider<DeckController, DeckState>((ref) {
  return DeckController(ref);
});
