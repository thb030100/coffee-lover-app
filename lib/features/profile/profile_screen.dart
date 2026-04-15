import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/shop.dart';
import '../onboarding/preferences_screen.dart';
import '../shop_detail/shop_detail_sheet.dart';

final savedShopsProvider = FutureProvider<List<Shop>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(shopRepositoryProvider).fetchSavedShops(user.id);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final saved = ref.watch(savedShopsProvider);
    final prefsAsync = ref.watch(userPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(supabaseClientProvider).auth.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedShopsProvider);
          ref.invalidate(userPreferencesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              user?.email ?? 'Signed in',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Preferences summary card
            prefsAsync.when(
              data: (prefs) {
                if (prefs == null) return const SizedBox.shrink();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.tune, color: kIgPink),
                    title: const Text('Preferences'),
                    subtitle: Text(
                      [
                        if (prefs.priceMax != null) 'Max ${'₫' * prefs.priceMax!}',
                        '${prefs.maxDistanceKm.toStringAsFixed(1)} km',
                        if (prefs.preferredTags.isNotEmpty)
                          '${prefs.preferredTags.length} tags',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editPreferences(context, ref, prefs),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),
            Text('Saved shops',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            saved.when(
              data: (shops) {
                if (shops.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Swipe up on a card to save it here.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }
                return Column(
                  children: shops.map((s) => _SavedTile(shop: s)).toList(),
                );
              },
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Failed to load: $e',
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _editPreferences(BuildContext context, WidgetRef ref, dynamic prefs) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreferencesScreen(
          initial: prefs,
          onComplete: () {
            ref.invalidate(userPreferencesProvider);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(shop.displayName),
        subtitle: Text(shop.address ?? ''),
        trailing: shop.priceLevel == null
            ? null
            : Text('₫' * shop.priceLevel!),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => ShopDetailSheet(shop: shop),
        ),
      ),
    );
  }
}
