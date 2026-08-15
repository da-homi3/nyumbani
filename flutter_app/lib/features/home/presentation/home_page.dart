import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/home/presentation/home_testimonials.dart';
import 'package:nyumbasearch/features/home/presentation/neighborhood_card.dart';
import 'package:nyumbasearch/features/properties/data/listings_providers.dart';
import 'package:nyumbasearch/features/properties/presentation/property_card.dart';
import 'package:nyumbasearch/shared/widgets/ambient_backdrop.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/motion.dart';
import 'package:nyumbasearch/shared/widgets/site_top_bar.dart';

/// Popular neighborhoods shown on home / browse (matches mobile web).
const kPopularNeighborhoods = <String>[
  'Kilimani',
  'Westlands',
  'Karen',
  'Lavington',
  'South B',
  'South C',
  'Rongai',
  'Kileleshwa',
  'Parklands',
  'Ngong Road',
];

const kPropertyTypes = <({String? value, String label})>[
  (value: null, label: 'Any type'),
  (value: 'bedsitter', label: 'Bedsitter'),
  (value: 'single_room', label: 'Single Room'),
  (value: 'studio', label: 'Studio'),
  (value: 'hostel', label: 'Hostel'),
  (value: '1_bedroom', label: '1 bedroom'),
  (value: '2_bedroom', label: '2 bedroom'),
  (value: '3_bedroom', label: '3 bedroom'),
  (value: 'apartment', label: 'Apartment'),
  (value: 'maisonette', label: 'Maisonette'),
  (value: 'bungalow', label: 'Bungalow'),
];

/// Fallback hero when listings have no images yet.
const _kHeroFallback =
    'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1400&q=80';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _neighborhood;
  int? _maxBudget;
  String? _type;

  void _applyAndBrowse() {
    ref.read(searchFiltersProvider.notifier).update(
          (f) => f.copyWith(
            neighborhood: _neighborhood,
            maxRent: _maxBudget,
            type: _type,
            clearNeighborhood: _neighborhood == null,
            clearMaxRent: _maxBudget == null,
            clearType: _type == null,
            pricingMode: 'rent',
          ),
        );
    context.go('/search');
  }

  Future<void> _pickNeighborhood() async {
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Any neighborhood'),
                onTap: () => Navigator.pop(ctx, ''),
              ),
              for (final n in kPopularNeighborhoods)
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(n),
                  onTap: () => Navigator.pop(ctx, n),
                ),
            ],
          ),
        );
      },
    );
    if (chosen == null) return;
    setState(() => _neighborhood = chosen.isEmpty ? null : chosen);
  }

  Future<void> _pickBudget() async {
    final ctrl = TextEditingController(
      text: _maxBudget?.toString() ?? '',
    );
    final value = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Max budget (KES)'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. 25000',
              prefixText: 'KES ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, -1),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(ctrl.text.replaceAll(',', '').trim());
                Navigator.pop(ctx, n);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
    if (value == null) return;
    setState(() => _maxBudget = value < 0 ? null : value);
  }

  Future<void> _pickType() async {
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final t in kPropertyTypes)
                ListTile(
                  title: Text(t.label),
                  onTap: () => Navigator.pop(ctx, t.value ?? ''),
                ),
            ],
          ),
        );
      },
    );
    if (chosen == null) return;
    setState(() => _type = chosen.isEmpty ? null : chosen);
  }

  String get _typeLabel {
    for (final t in kPropertyTypes) {
      if (t.value == _type) return t.label;
    }
    return 'Any type';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(homeListingsProvider);
    final bottomPad = NyumbaTokens.shellBottomInset(context);
    final heroUrl = async.maybeWhen(
      data: (page) {
        for (final item in page.items) {
          if (item.primaryImage.isNotEmpty) return item.primaryImage;
        }
        return _kHeroFallback;
      },
      orElse: () => _kHeroFallback,
    );
    final total = async.maybeWhen(data: (p) => p.total, orElse: () => 0);
    final loadingStats = async.isLoading || async.hasError;
    final verifiedLabel = total > 0
        ? '$total verified homes · ${kPopularNeighborhoods.length}+ neighborhoods'
        : async.isLoading
            ? 'Loading verified homes…'
            : 'Verified homes · Nairobi neighborhoods';

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: NyumbaTokens.primaryGlowDark,
        onRefresh: () async => ref.invalidate(homeListingsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: NyumbaTokens.durationSlow,
                      switchInCurve: NyumbaTokens.easeOutSoft,
                      switchOutCurve: NyumbaTokens.easeSmooth,
                      child: CachedNetworkImage(
                        key: ValueKey(heroUrl),
                        imageUrl: heroUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const ColoredBox(color: Color(0xFF0B1220)),
                        errorWidget: (_, _, _) =>
                            const ColoredBox(color: Color(0xFF0B1220)),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x66111827),
                            Color(0x99111827),
                            Color(0xF2111827),
                          ],
                          stops: [0, 0.4, 1],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(child: HeroOrbsLayer(particleCount: 70)),
                  const Positioned.fill(
                    child: AmbientBackdrop(opacity: 0.32, particleCount: 16),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SiteTopBar(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatsChip(label: verifiedLabel),
                            const SizedBox(height: 16),
                            Text.rich(
                              TextSpan(
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                children: const [
                                  TextSpan(text: 'Your next home in Nairobi —\n'),
                                  TextSpan(
                                    text: 'deal with verified property owners.',
                                    style: TextStyle(color: Color(0xFF22C55E)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'NyumbaSearch (nyumbasearch.com): map-first verified home search across Nairobi. Real reviews. AI that warns about red flags before you visit.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    height: 1.35,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            _HomeSearchCard(
                              neighborhood: _neighborhood,
                              maxBudget: _maxBudget,
                              typeLabel: _typeLabel,
                              onNeighborhood: _pickNeighborhood,
                              onBudget: _pickBudget,
                              onType: _pickType,
                              onSearch: _applyAndBrowse,
                            ),
                            const SizedBox(height: 14),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Text(
                                    'Popular: ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.55),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  for (final n in const [
                                    'Kilimani',
                                    'Westlands',
                                    'Karen',
                                    'Lavington',
                                    'Kasarani',
                                  ])
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ActionChip(
                                        label: Text(n),
                                        onPressed: () {
                                          setState(() => _neighborhood = n);
                                          _applyAndBrowse();
                                        },
                                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                                        side: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.15),
                                        ),
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _applyAndBrowse,
                                    icon: const Icon(Icons.arrow_forward, size: 18),
                                    label: const Text('Browse homes'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF22C55E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.go('/map'),
                                    icon: const Icon(Icons.map_outlined, size: 18),
                                    label: const Text('Open the map'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.35),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _HomeStatsRow(totalHomes: total, loading: loadingStats),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: ColoredBox(
                color: const Color(0xFF0B1220),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POPULAR NEIGHBORHOODS',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF22C55E),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Where Nairobi lives',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: kPopularNeighborhoods.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final n = kPopularNeighborhoods[i];
                            return NeighborhoodCard(
                              name: n,
                              onTap: () {
                                setState(() => _neighborhood = n);
                                _applyAndBrowse();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ColoredBox(
                color: const Color(0xFF0B1220),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: const HomeTestimonialsCarousel(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ColoredBox(
                color: const Color(0xFF0B1220),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FEATURED',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF22C55E),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Verified homes',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AsyncSliverBody(
              async: async,
              onRetry: () => ref.invalidate(homeListingsProvider),
              compact: true,
              data: (page) {
                if (page.items.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                final items = page.items.take(6).toList();
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) => PropertyCard(listing: items[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeStatsRow extends StatelessWidget {
  const _HomeStatsRow({required this.totalHomes, this.loading = false});
  final int totalHomes;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Row(
        children: [
          Expanded(child: _StatPlaceholder()),
          Expanded(child: _StatPlaceholder()),
          Expanded(child: _StatPlaceholder()),
          Expanded(child: _StatPlaceholder()),
        ],
      );
    }
    final homes = totalHomes > 0 ? totalHomes : 0;
    final hoods = kPopularNeighborhoods.length;
    return Row(
      children: [
        Expanded(
          child: AnimatedStat(
            value: homes,
            label: 'Verified homes',
            suffix: homes > 0 ? '+' : '',
          ),
        ),
        Expanded(
          child: AnimatedStat(value: hoods, label: 'Neighborhoods', suffix: '+'),
        ),
        const Expanded(
          child: _QualStat(value: 'Map', label: 'First search'),
        ),
        const Expanded(
          child: _QualStat(value: 'AI', label: 'Red-flag alerts'),
        ),
      ],
    );
  }
}

class _QualStat extends StatelessWidget {
  const _QualStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF22C55E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatPlaceholder extends StatelessWidget {
  const _StatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 56,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _StatsChip extends StatelessWidget {
  const _StatsChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchCard extends StatelessWidget {
  const _HomeSearchCard({
    required this.neighborhood,
    required this.maxBudget,
    required this.typeLabel,
    required this.onNeighborhood,
    required this.onBudget,
    required this.onType,
    required this.onSearch,
  });

  final String? neighborhood;
  final int? maxBudget;
  final String typeLabel;
  final VoidCallback onNeighborhood;
  final VoidCallback onBudget;
  final VoidCallback onType;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _SearchRow(
                icon: Icons.place_outlined,
                label: neighborhood ?? 'Neighborhood',
                muted: neighborhood == null,
                trailing: Icons.keyboard_arrow_down,
                onTap: onNeighborhood,
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              _SearchRow(
                leadingText: 'KES',
                label: maxBudget == null
                    ? 'Max budget'
                    : ListingFormat.kes(maxBudget!),
                muted: maxBudget == null,
                onTap: onBudget,
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              _SearchRow(
                icon: Icons.search,
                label: typeLabel,
                muted: typeLabel == 'Any type',
                trailing: Icons.unfold_more,
                onTap: onType,
              ),
              Material(
                color: const Color(0xFF22C55E),
                child: InkWell(
                  onTap: onSearch,
                  child: const SizedBox(
                    height: 8,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.label,
    required this.muted,
    required this.onTap,
    this.icon,
    this.leadingText,
    this.trailing,
  });

  final IconData? icon;
  final String? leadingText;
  final String label;
  final bool muted;
  final IconData? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.7))
            else if (leadingText != null)
              Text(
                leadingText!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: muted
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.white,
                  fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 18, color: const Color(0xFF60A5FA)),
          ],
        ),
      ),
    );
  }
}

abstract final class ListingFormat {
  static String kes(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
