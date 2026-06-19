import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shop.dart';
import '../models/swipe.dart';
import 'recommendation_service.dart';

/// Supabase-backed data access for shops, swipes, and saved shops.
class ShopRepository {
  ShopRepository(this._client);
  final SupabaseClient _client;

  /// Fetch all shops (MVP: Hanoi-only, small set — no pagination yet).
  Future<List<Shop>> fetchAllShops() async {
    final rows = await _client.from('shops').select();
    return (rows as List)
        .map((r) => Shop.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Shop IDs this user has swiped in the last [window].
  /// Used by the recommendation service to avoid re-showing recent cards.
  Future<Set<String>> recentlySwipedShopIds(
    String userId, {
    Duration window = const Duration(days: 7),
  }) async {
    final cutoff = DateTime.now().toUtc().subtract(window).toIso8601String();
    final rows = await _client
        .from('swipes')
        .select('shop_id')
        .eq('user_id', userId)
        .gte('created_at', cutoff);
    return (rows as List)
        .map((r) => (r as Map<String, dynamic>)['shop_id'] as String)
        .toSet();
  }

  Future<void> recordSwipe({
    required String userId,
    required String shopId,
    required SwipeDirection direction,
  }) async {
    await _client.from('swipes').insert({
      'user_id': userId,
      'shop_id': shopId,
      'direction': swipeDirectionToDb(direction),
    });
    if (direction == SwipeDirection.up) {
      // DO NOTHING on conflict: re-saving an already-saved shop is a no-op and
      // keeps the original saved_at. Avoids the ON CONFLICT DO UPDATE path,
      // which saved_shops has no RLS update policy for.
      await _client.from('saved_shops').upsert(
        {
          'user_id': userId,
          'shop_id': shopId,
        },
        ignoreDuplicates: true,
      );
    }
  }

  Future<List<Shop>> fetchSavedShops(String userId) async {
    final rows = await _client
        .from('saved_shops')
        .select('shop:shops(*), saved_at')
        .eq('user_id', userId)
        .order('saved_at', ascending: false);
    return (rows as List)
        .map((r) => Shop.fromJson(
            (r as Map<String, dynamic>)['shop'] as Map<String, dynamic>))
        .toList();
  }

  /// Fetch the user's preferences from the profiles table.
  /// Returns null if no preferences have been set yet.
  Future<UserPreferences?> fetchPreferences(String userId) async {
    final rows = await _client
        .from('profiles')
        .select('preferences')
        .eq('id', userId)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    final prefs = (list.first as Map<String, dynamic>)['preferences'];
    if (prefs == null) return null;
    return UserPreferences.fromJson(prefs as Map<String, dynamic>);
  }

  /// Update the user's preferences in profiles.preferences jsonb column.
  /// The profile row is created by the on_auth_user_created trigger, so this is
  /// always an UPDATE — an upsert would emit INSERT ... ON CONFLICT, which
  /// profiles has no RLS insert policy for and would be rejected.
  Future<void> savePreferences(String userId, UserPreferences prefs) async {
    await _client.from('profiles').update({
      'preferences': prefs.toJson(),
    }).eq('id', userId);
  }

  Future<Shop?> mostRecentRightSwipe(String userId) async {
    final rows = await _client
        .from('swipes')
        .select('shop:shops(*), created_at')
        .eq('user_id', userId)
        .eq('direction', 'right')
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return Shop.fromJson((list.first as Map<String, dynamic>)['shop']
        as Map<String, dynamic>);
  }
}
