import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gradient_button.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/shop.dart';
import '../shop_detail/shop_detail_sheet.dart';

/// "Today's pick" = most recent right-swipe, falling back to a random saved shop.
final todaysPickProvider = FutureProvider<Shop?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.watch(shopRepositoryProvider);
  // Try last right-swipe first
  final pick = await repo.mostRecentRightSwipe(user.id);
  if (pick != null) return pick;
  // Fall back to a random saved shop
  final saved = await repo.fetchSavedShops(user.id);
  if (saved.isEmpty) return null;
  saved.shuffle();
  return saved.first;
});

class TodaysPickScreen extends ConsumerWidget {
  const TodaysPickScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickAsync = ref.watch(todaysPickProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Pick")),
      body: pickAsync.when(
        data: (shop) {
          if (shop == null) return _empty(context);
          return _pickCard(context, shop);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_cafe_outlined, size: 64, color: Colors.black26),
            const SizedBox(height: 12),
            Text('No pick yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Swipe right on a shop you like and it\'ll show up here as your daily pick.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickCard(BuildContext context, Shop shop) {
    final photoUrl = shop.photoUrls.isNotEmpty ? shop.photoUrls.first : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openDetail(context, shop),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: photoUrl != null
                          ? Image.network(photoUrl, fit: BoxFit.cover)
                          : Container(
                              color: kBorder,
                              child: const Icon(Icons.local_cafe,
                                  size: 64, color: Colors.black26),
                            ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            if (shop.address != null) ...[
                              const SizedBox(height: 6),
                              Text(shop.address!,
                                  style: TextStyle(color: kTextSecondary)),
                            ],
                            const SizedBox(height: 8),
                            if (shop.tags.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: shop.tags
                                    .take(4)
                                    .map((t) => Chip(
                                          label: Text(t.replaceAll('_', ' ')),
                                          visualDensity: VisualDensity.compact,
                                        ))
                                    .toList(),
                              ),
                            const Spacer(),
                            Row(
                              children: [
                                if (shop.priceLevel != null)
                                  Text('₫' * shop.priceLevel!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                const Spacer(),
                                if (shop.googleRating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: kIgOrange, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                          shop.googleRating!
                                              .toStringAsFixed(1),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GradientFilledButton(
              label: 'View details',
              icon: Icons.coffee,
              onPressed: () => _openDetail(context, shop),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, Shop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ShopDetailSheet(shop: shop),
    );
  }
}
