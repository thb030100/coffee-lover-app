import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/shop.dart';
import '../../services/places_service.dart';

class ShopCard extends StatelessWidget {
  const ShopCard({
    super.key,
    required this.shop,
    required this.distanceKm,
    required this.onTap,
  });

  final Shop shop;
  final double distanceKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hero = _resolveHeroImageUrl(shop);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hero != null)
              CachedNetworkImage(
                imageUrl: hero,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade300),
                errorWidget: (_, __, ___) =>
                    Container(color: Colors.grey.shade400, child: const Icon(Icons.local_cafe, size: 64, color: Colors.white70)),
              )
            else
              Container(color: Colors.grey.shade300, child: const Center(child: Icon(Icons.local_cafe, size: 64, color: Colors.white70))),
            // Gradient scrim so text is readable
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
            if (shop.isPromoted)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Sponsored',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip('${distanceKm.toStringAsFixed(1)} km'),
                      if (shop.priceLevel != null) ...[
                        const SizedBox(width: 6),
                        _chip('₫' * shop.priceLevel!),
                      ],
                      if (shop.googleRating != null) ...[
                        const SizedBox(width: 6),
                        _chip('★ ${shop.googleRating!.toStringAsFixed(1)}'),
                      ],
                    ],
                  ),
                  if (shop.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: shop.tags.take(3).map(_tag).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  static Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('#${t.replaceAll('_', ' ')}',
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      );
}

String? _resolveHeroImageUrl(Shop shop) {
  if (shop.photoUrls.isNotEmpty) return shop.photoUrls.first;
  if (shop.photoRefs.isNotEmpty) {
    try {
      return PlacesService().photoUrl(shop.photoRefs.first);
    } catch (_) {
      return null; // env not loaded, e.g. in tests
    }
  }
  return null;
}
