import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/gradient_button.dart';
import '../../models/shop.dart';
import '../../services/places_service.dart';

class ShopDetailSheet extends StatelessWidget {
  const ShopDetailSheet({super.key, required this.shop});
  final Shop shop;

  List<String> get _photoUrls {
    if (shop.photoUrls.isNotEmpty) return shop.photoUrls;
    try {
      return shop.photoRefs
          .map((ref) => PlacesService().photoUrl(ref, maxWidth: 1200))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photoUrls;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (photos.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 260,
                  viewportFraction: 1,
                  enableInfiniteScroll: false,
                ),
                items: photos
                    .map((u) => CachedNetworkImage(
                          imageUrl: u,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ))
                    .toList(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  if (shop.name != shop.displayName)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(shop.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              )),
                    ),
                  const SizedBox(height: 12),
                  _metaRow(context),
                  const SizedBox(height: 16),
                  if (shop.address != null) _row(Icons.place, shop.address!),
                  if (shop.phone != null) _row(Icons.phone, shop.phone!),
                  _hoursSection(context),
                  if (shop.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: shop.tags
                          .map((t) => Chip(label: Text('#${t.replaceAll('_', ' ')}')))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GradientFilledButton(
                          label: 'Directions',
                          icon: Icons.directions,
                          onPressed: () => _openMaps(context),
                        ),
                      ),
                      if (shop.phone != null) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.call),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () =>
                              launchUrl(Uri.parse('tel:${shop.phone}')),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metaRow(BuildContext context) {
    final parts = <String>[];
    if (shop.googleRating != null) {
      parts.add('★ ${shop.googleRating!.toStringAsFixed(1)}');
    }
    if (shop.priceLevel != null) parts.add('₫' * shop.priceLevel!);
    return Text(parts.join('  ·  '),
        style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );

  Widget _hoursSection(BuildContext context) {
    final weekday = shop.hours?['weekday_text'];
    if (weekday is! List) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hours', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          for (final line in weekday)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(line.toString(),
                  style: const TextStyle(color: Colors.black87)),
            ),
          const SizedBox(height: 4),
          const Text(
            'Hours on Google can be out of date in Hanoi — call ahead if in doubt.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final available = await MapLauncher.installedMaps;
    if (available.isEmpty) return;
    // Prefer Apple Maps on iOS, Google Maps elsewhere.
    final preferred = available.firstWhere(
      (m) => m.mapType == MapType.apple || m.mapType == MapType.google,
      orElse: () => available.first,
    );
    await preferred.showMarker(
      coords: Coords(shop.lat, shop.lng),
      title: shop.displayName,
    );
  }
}
