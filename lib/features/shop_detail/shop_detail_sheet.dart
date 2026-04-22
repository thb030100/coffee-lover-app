import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/gradient_button.dart';
import '../../core/tags.dart';
import '../../core/theme.dart';
import '../../models/shop.dart';
import '../../services/places_service.dart';

class _Amenity {
  final IconData iconOn;
  final IconData iconOff;
  final String label;
  final bool active;
  const _Amenity({
    required this.iconOn,
    required this.iconOff,
    required this.label,
    required this.active,
  });
}

class ShopDetailSheet extends StatefulWidget {
  const ShopDetailSheet({super.key, required this.shop});
  final Shop shop;

  @override
  State<ShopDetailSheet> createState() => _ShopDetailSheetState();
}

class _ShopDetailSheetState extends State<ShopDetailSheet> {
  int _currentPhoto = 0;

  List<String> get _photoUrls {
    if (widget.shop.photoUrls.isNotEmpty) return widget.shop.photoUrls;
    try {
      return widget.shop.photoRefs
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
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (photos.isNotEmpty) ...[
              CarouselSlider(
                options: CarouselOptions(
                  height: 260,
                  viewportFraction: 1,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, _) =>
                      setState(() => _currentPhoto = index),
                ),
                items: photos
                    .map((u) => CachedNetworkImage(
                          imageUrl: u,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, _) =>
                              Container(color: kBorder),
                          errorWidget: (_, _, _) => Container(
                            color: kBorder,
                            child: const Icon(Icons.local_cafe,
                                size: 48, color: kTextSecondary),
                          ),
                        ))
                    .toList(),
              ),
              if (photos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(photos.length, (i) {
                      final active = i == _currentPhoto;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 8 : 6,
                        height: active ? 8 : 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? kIgPink : kBorder,
                        ),
                      );
                    }),
                  ),
                ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.shop.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (widget.shop.name != widget.shop.displayName)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(widget.shop.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: kTextSecondary)),
                    ),
                  const SizedBox(height: 12),
                  _metaRow(context),
                  _amenitiesSection(context),
                  const SizedBox(height: 16),
                  if (widget.shop.address != null)
                    _row(Icons.place, widget.shop.address!),
                  if (widget.shop.phone != null)
                    _row(Icons.phone, widget.shop.phone!),
                  _hoursSection(context),
                  if (widget.shop.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.shop.tags
                          .map((t) => Chip(label: Text('#${displayTag(t)}')))
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
                      if (widget.shop.phone != null) ...[
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
                              launchUrl(Uri.parse('tel:${widget.shop.phone}')),
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

  List<_Amenity> _buildAmenities() => [
        _Amenity(
          iconOn: Icons.wifi,
          iconOff: Icons.wifi_off,
          label: 'Wi-Fi',
          active: widget.shop.tags.contains('wifi'),
        ),
        _Amenity(
          iconOn: Icons.smoking_rooms,
          iconOff: Icons.smoke_free,
          label: 'Smoking',
          active: widget.shop.tags.contains('smoking_allowed'),
        ),
        _Amenity(
          iconOn: Icons.pets,
          iconOff: Icons.pets,
          label: 'Pets OK',
          active: widget.shop.tags.contains('pet_friendly'),
        ),
        _Amenity(
          iconOn: Icons.cake,
          iconOff: Icons.cake,
          label: 'Cakes',
          active: widget.shop.tags.contains('cake') ||
              widget.shop.tags.contains('bakery'),
        ),
        _Amenity(
          iconOn: Icons.local_parking,
          iconOff: Icons.local_parking,
          label: 'Parking',
          active: widget.shop.tags.contains('car_parking'),
        ),
      ];

  Widget _amenitiesSection(BuildContext context) {
    final amenities = _buildAmenities().where((a) => a.active).toList();
    if (amenities.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amenities',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: kTextPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities
                .map((a) => _amenityChip(context, a))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _amenityChip(BuildContext context, _Amenity amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(amenity.iconOn, size: 16, color: kTextPrimary),
          const SizedBox(width: 5),
          Text(
            amenity.label,
            style: const TextStyle(
              fontSize: 12,
              color: kTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context) {
    final parts = <String>[];
    if (widget.shop.googleRating != null) {
      parts.add('★ ${widget.shop.googleRating!.toStringAsFixed(1)}');
    }
    if (widget.shop.priceLevel != null) {
      parts.add('₫' * widget.shop.priceLevel!);
    }
    return Text(
      parts.join('  ·  '),
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: kTextSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: kTextPrimary)),
            ),
          ],
        ),
      );

  Widget _hoursSection(BuildContext context) {
    final weekday = widget.shop.hours?['weekday_text'];
    if (weekday is! List) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hours',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 4),
          for (final line in weekday)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(line.toString(),
                  style: const TextStyle(color: kTextPrimary)),
            ),
          const SizedBox(height: 4),
          const Text(
            'Hours on Google can be out of date in Hanoi — call ahead if in doubt.',
            style: TextStyle(fontSize: 11, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final available = await MapLauncher.installedMaps;
    if (available.isEmpty) return;
    final preferred = available.firstWhere(
      (m) => m.mapType == MapType.apple || m.mapType == MapType.google,
      orElse: () => available.first,
    );
    await preferred.showMarker(
      coords: Coords(widget.shop.lat, widget.shop.lng),
      title: widget.shop.displayName,
    );
  }
}
