import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gradient_button.dart';
import '../../core/providers.dart';
import '../../core/tags.dart';
import '../../core/theme.dart';
import '../../services/recommendation_service.dart';

/// Onboarding preferences screen shown after first sign-in.
/// Collects price range, vibe tags, and max walking distance.
class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key, this.initial, this.onComplete});

  /// If non-null, we're editing existing preferences (profile tab).
  final UserPreferences? initial;

  /// Called after save. In onboarding this navigates to the home shell;
  /// when editing from profile it pops the screen.
  final VoidCallback? onComplete;

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  int _page = 0;
  int? _priceMax;
  double _maxDistanceKm = 3.0;
  final Set<String> _selectedTags = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _priceMax = init.priceMax;
      _maxDistanceKm = init.maxDistanceKm;
      _selectedTags.addAll(init.preferredTags);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Your Preferences' : 'Edit Preferences'),
        leading: widget.initial != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_page + 1) / 3,
              backgroundColor: kBorder,
              color: kIgPink,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: [
                  _buildPricePage(),
                  _buildTagsPage(),
                  _buildDistancePage(),
                ][_page],
              ),
            ),
            _buildNavRow(),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Price range ──

  Widget _buildPricePage() {
    return Padding(
      key: const ValueKey('price'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What\'s your budget?',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('We\'ll hide shops above your max price.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: kTextSecondary)),
          const SizedBox(height: 32),
          ...[
            (1, '₫', 'Street cà phê (15-25k)'),
            (2, '₫₫', 'Local cafés (30-55k)'),
            (3, '₫₫₫', 'Specialty coffee (60-100k)'),
            (4, '₫₫₫₫', 'Premium / import (100k+)'),
          ].map((e) => _priceOption(e.$1, e.$2, e.$3)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _priceMax = null),
            child: Text(
              'No limit',
              style: TextStyle(
                color: _priceMax == null ? kIgPink : kTextSecondary,
                fontWeight:
                    _priceMax == null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceOption(int level, String label, String description) {
    final selected = _priceMax == level;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? kIgPink.withValues(alpha: 0.08) : kSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _priceMax = level),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? kIgPink : kBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected ? kIgPink : kTextPrimary,
                    )),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(description,
                      style: TextStyle(color: kTextSecondary, fontSize: 14)),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: kIgPink, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Page 2: Vibe tags ──

  Widget _buildTagsPage() {
    // Group tags into categories for readability.
    final vibes = kShopTagVocabulary
        .where((t) => const {
              'quiet', 'lively', 'cozy', 'minimalist', 'traditional',
              'instagrammable'
            }.contains(t))
        .toList();
    final practical = kShopTagVocabulary
        .where((t) => const {
              'wifi', 'power_outlets', 'work_friendly', 'meeting_friendly',
              'open_late', 'open_early', 'pet_friendly'
            }.contains(t))
        .toList();
    final coffee = kShopTagVocabulary
        .where((t) => const {
              'specialty', 'vietnamese_traditional', 'egg_coffee',
              'coconut_coffee', 'drip_phin', 'pour_over', 'espresso'
            }.contains(t))
        .toList();
    final setting = kShopTagVocabulary
        .where((t) =>
            const {'outdoor', 'rooftop', 'garden', 'alleyway', 'view'}
                .contains(t))
        .toList();

    return SingleChildScrollView(
      key: const ValueKey('tags'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What\'s your vibe?',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Pick as many as you like — we\'ll boost matching shops.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: kTextSecondary)),
          const SizedBox(height: 24),
          _tagSection('Atmosphere', vibes),
          _tagSection('Practical', practical),
          _tagSection('Coffee style', coffee),
          _tagSection('Setting', setting),
        ],
      ),
    );
  }

  Widget _tagSection(String title, List<String> tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: kTextSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: tags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(_displayTag(tag)),
                selected: selected,
                selectedColor: kIgPink.withValues(alpha: 0.15),
                checkmarkColor: kIgPink,
                onSelected: (on) => setState(() {
                  on ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _displayTag(String tag) {
    return tag.replaceAll('_', ' ');
  }

  // ── Page 3: Distance ──

  Widget _buildDistancePage() {
    return Padding(
      key: const ValueKey('distance'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How far will you go?',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Set your max distance from your current location.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: kTextSecondary)),
          const SizedBox(height: 48),
          Center(
            child: Text(
              '${_maxDistanceKm.toStringAsFixed(1)} km',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _maxDistanceKm,
            min: 0.5,
            max: 10.0,
            divisions: 19,
            activeColor: kIgPink,
            label: '${_maxDistanceKm.toStringAsFixed(1)} km',
            onChanged: (v) => setState(() => _maxDistanceKm = v),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.5 km', style: TextStyle(color: kTextSecondary, fontSize: 12)),
              Text('10 km', style: TextStyle(color: kTextSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _distanceHint(),
              style: TextStyle(color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _distanceHint() {
    if (_maxDistanceKm <= 1.0) return 'Walking distance only — the closest spots.';
    if (_maxDistanceKm <= 3.0) return 'A comfortable bike ride in Hanoi.';
    if (_maxDistanceKm <= 5.0) return 'Covers most of central Hanoi.';
    return 'You\'ll see shops across the whole city.';
  }

  // ── Navigation ──

  Widget _buildNavRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          if (_page > 0)
            TextButton(
              onPressed: () => setState(() => _page--),
              child: const Text('Back'),
            ),
          const Spacer(),
          if (_page < 2)
            FilledButton(
              onPressed: () => setState(() => _page++),
              child: const Text('Next'),
            )
          else
            GradientFilledButton(
              label: _saving ? 'Saving…' : 'Let\'s go!',
              icon: Icons.local_cafe,
              onPressed: _saving ? () {} : _save,
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final prefs = UserPreferences(
        priceMax: _priceMax,
        maxDistanceKm: _maxDistanceKm,
        preferredTags: _selectedTags,
      );
      await ref.read(shopRepositoryProvider).savePreferences(user.id, prefs);
      // Invalidate the cached preferences so the app picks them up.
      ref.invalidate(userPreferencesProvider);
      if (mounted) {
        widget.onComplete?.call();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
