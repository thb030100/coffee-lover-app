import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/recommendation_service.dart' show RecommendationService, UserPreferences;
import '../services/shop_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(supabaseClientProvider));
});

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService(ref.watch(shopRepositoryProvider));
});

/// Emits the current Supabase auth state; null when signed out.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  ref.watch(authStateProvider); // rebuild when auth changes
  return client.auth.currentUser;
});

/// Fetches the current user's preferences from the profiles table.
/// Returns null if onboarding hasn't been completed.
final userPreferencesProvider = FutureProvider<UserPreferences?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(shopRepositoryProvider).fetchPreferences(user.id);
});
