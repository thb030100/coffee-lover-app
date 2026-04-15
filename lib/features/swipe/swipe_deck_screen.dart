import 'dart:math';

import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gradient_button.dart';
import '../../models/shop.dart';
import '../../models/swipe.dart' show SwipeDirection;
import '../shop_detail/shop_detail_sheet.dart';
import 'shop_card.dart';
import 'swipe_deck_controller.dart';

class SwipeDeckScreen extends ConsumerStatefulWidget {
  const SwipeDeckScreen({super.key});

  @override
  ConsumerState<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends ConsumerState<SwipeDeckScreen> {
  final _controller = AppinioSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  SwipeDirection? _mapDirection(SwiperActivity activity) {
    if (activity is! Swipe) return null;
    switch (activity.direction) {
      case AxisDirection.left:
        return SwipeDirection.left;
      case AxisDirection.right:
        return SwipeDirection.right;
      case AxisDirection.up:
        return SwipeDirection.up;
      case AxisDirection.down:
        return SwipeDirection.left; // treat as skip
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deckControllerProvider);
    final ctrl = ref.read(deckControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today in Hanoi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.load,
          ),
        ],
      ),
      body: _buildBody(state, ctrl),
    );
  }

  Widget _buildBody(DeckState state, DeckController ctrl) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return _centeredMessage(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        body: state.error!,
        action: ('Retry', ctrl.load),
      );
    }
    if (state.shops.isEmpty) {
      return _centeredMessage(
        icon: Icons.coffee_outlined,
        title: "That's all for today",
        body: 'Pull to refresh, widen your distance, or check back tomorrow.',
        action: ('Refresh', ctrl.load),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Expanded(
            child: AppinioSwiper(
              controller: _controller,
              cardCount: state.shops.length,
              cardBuilder: (_, i) {
                final shop = state.shops[i];
                return ShopCard(
                  shop: shop,
                  distanceKm: _distanceKm(state, shop),
                  onTap: () => _openDetail(shop),
                );
              },
              onSwipeEnd: (prev, target, activity) {
                final dir = _mapDirection(activity);
                if (dir == null) return;
                final shop = state.shops[prev];
                ctrl.recordSwipe(shop, dir);
              },
              onEnd: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('End of deck — pull for more')),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _actionRow(),
        ],
      ),
    );
  }

  Widget _actionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _outlinedCircle(
          icon: Icons.close,
          color: const Color(0xFFE94F4F),
          onPressed: () => _controller.swipeLeft(),
        ),
        _outlinedCircle(
          icon: Icons.bookmark_border,
          color: const Color(0xFF3D7DFF),
          onPressed: () => _controller.swipeUp(),
        ),
        // The one gradient button — primary action wins visually.
        GradientCircleButton(
          icon: Icons.favorite,
          onPressed: () => _controller.swipeRight(),
        ),
      ],
    );
  }

  Widget _outlinedCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      shape: CircleBorder(side: BorderSide(color: color.withValues(alpha: 0.6))),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }

  void _openDetail(Shop shop) {
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

  double _distanceKm(DeckState state, Shop shop) {
    final lat = state.userLat, lng = state.userLng;
    if (lat == null || lng == null) return 0;
    const r = 6371.0;
    final dLat = (shop.lat - lat) * pi / 180;
    final dLng = (shop.lng - lng) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * pi / 180) *
            cos(shop.lat * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Widget _centeredMessage({
    required IconData icon,
    required String title,
    required String body,
    (String, VoidCallback)? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.black26),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: action.$2, child: Text(action.$1)),
            ],
          ],
        ),
      ),
    );
  }
}
