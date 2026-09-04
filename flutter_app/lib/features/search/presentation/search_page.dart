import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/analytics/analytics_client.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/home/presentation/home_page.dart'
    show kPopularNeighborhoods, kPropertyTypes;
import 'package:nyumbasearch/features/properties/data/listings_providers.dart';
import 'package:nyumbasearch/features/properties/presentation/property_card.dart';
import 'package:nyumbasearch/features/search/nl_search_apply.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';
import 'package:nyumbasearch/shared/widgets/nyumba_ai_fab.dart';
import 'package:nyumbasearch/shared/widgets/site_top_bar.dart';

const _kBrowseHero =
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1400&q=80';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  var _filtersExpanded = false;
  List<String> _nlHints = const [];

  Future<void> _applyNlSearch(String raw) async {
    final parsed = await fetchNlSearch(ref, raw);
    if (parsed == null) return;
    setState(() => _nlHints = parsed.hints);
    applyNlSearchToFilters(ref, parsed);
    _controller.text = parsed.remainingQuery;
  }

  @override
  void initState() {
    super.initState();
    final q = ref.read(searchFiltersProvider).q;
    if (q.isNotEmpty) _controller.text = q;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _trackSearch({String? q, String? neighborhood}) {
    final props = <String, Object?>{};
    if (q != null && q.isNotEmpty) props['q'] = q;
    if (neighborhood != null && neighborhood.isNotEmpty) {
      props['neighborhood'] = neighborhood;
    }
    if (props.isEmpty) return;
    ref.read(analyticsProvider).track(AnalyticsEvents.propertySearch, props);
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = value.trim();
      ref.read(searchFiltersProvider.notifier).update(
            (f) => f.copyWith(q: trimmed),
          );
      if (trimmed.isNotEmpty) _trackSearch(q: trimmed);
    });
  }

  void _setChipQuery(String value) {
    _controller.text = value;
    ref.read(searchFiltersProvider.notifier).update(
          (f) => f.copyWith(q: value, clearNeighborhood: true, clearLocationId: true),
        );
    _trackSearch(q: value);
  }

  Future<void> _setNeighborhood(String value) async {
    _controller.text = value;
    String? locationId;
    try {
      final res = await ref.read(mobileApiRepositoryProvider).resolveLocation(q: value);
      final loc = res['location'];
      if (loc is Map) locationId = loc['id']?.toString();
    } catch (_) {}
    if (locationId != null && locationId.isNotEmpty) {
      unawaited(
        ref.read(mobileApiRepositoryProvider).recordLocationSelect(
              locationId: locationId,
              q: value,
            ),
      );
    }
    ref.read(searchFiltersProvider.notifier).update(
          (f) => f.copyWith(
            neighborhood: value,
            locationId: locationId,
            q: '',
            clearLocationId: locationId == null,
          ),
        );
    _trackSearch(neighborhood: value);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final async = ref.watch(searchListingsProvider);
    final theme = Theme.of(context);
    final bottomPad = NyumbaTokens.shellBottomInset(context);
    final total = async.maybeWhen(data: (p) => p.total, orElse: () => 0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomPad - 72),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AskNyumbaAiBar(),
            SizedBox(height: 10),
            NyumbaAiFab(),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(searchListingsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 280,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _kBrowseHero,
                          fit: BoxFit.cover,
                          color: NyumbaTokens.espresso.withValues(alpha: 0.45),
                          colorBlendMode: BlendMode.darken,
                          errorWidget: (_, _, _) =>
                              const ColoredBox(color: Color(0xFF0B1220)),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x99111827),
                                Color(0xCC111827),
                                Color(0xFF111827),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            const SiteTopBar(),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'KARIBU',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white70,
                                        letterSpacing: 2.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Find your next home in Nairobi',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: NyumbaTokens.primaryGlowDark,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                      ),
                                    ),
                                    const Spacer(),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.45),
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.1),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.search,
                                                color: Colors.white.withValues(alpha: 0.7),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextField(
                                                  controller: _controller,
                                                  onChanged: _onQueryChanged,
                                                  onSubmitted: _applyNlSearch,
                                                  style: const TextStyle(color: Colors.white),
                                                  cursorColor: NyumbaTokens.primaryDark,
                                                  decoration: InputDecoration(
                                                    hintText: 'Try: 2 bedroom in Kilimani under 60k',
                                                    hintStyle: TextStyle(
                                                      color: Colors.white.withValues(alpha: 0.45),
                                                    ),
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                  ),
                                                ),
                                              ),
                                              Material(
                                                color: NyumbaTokens.primaryDark,
                                                shape: const CircleBorder(),
                                                child: IconButton(
                                                  tooltip: 'Near me / map',
                                                  onPressed: () => context.go('/map'),
                                                  icon: const Icon(
                                                    Icons.my_location,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_nlHints.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: _nlHints
                                            .map(
                                              (hint) => Chip(
                                                label: Text(
                                                  hint,
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                                visualDensity: VisualDensity.compact,
                                                backgroundColor:
                                                    Colors.white.withValues(alpha: 0.12),
                                                labelStyle: const TextStyle(color: Colors.white),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChipSection(
                          label: 'RECENT',
                          children: [
                            _BrowseChip(
                              label: 'Kilimani',
                              selected: filters.q == 'Kilimani' ||
                                  filters.neighborhood == 'Kilimani',
                              onTap: () => _setNeighborhood('Kilimani'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _ChipSection(
                          label: 'POPULAR',
                          children: [
                            for (final n in kPopularNeighborhoods.take(5))
                              _BrowseChip(
                                label: n,
                                selected: filters.neighborhood == n || filters.q == n,
                                onTap: () => _setNeighborhood(n),
                              ),
                            _BrowseChip(
                              label: '2 bedroom',
                              selected: filters.q == '2 bedroom',
                              onTap: () => _setChipQuery('2 bedroom'),
                            ),
                            _BrowseChip(
                              label: 'Bedsitter',
                              selected: filters.type == 'bedsitter',
                              onTap: () {
                                ref.read(searchFiltersProvider.notifier).update(
                                      (f) => f.copyWith(type: 'bedsitter'),
                                    );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => _filtersExpanded = !_filtersExpanded),
                                icon: const Icon(Icons.tune, size: 18),
                                label: const Text('Filters'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.onSurface,
                                  side: BorderSide(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              total > 0 ? '$total homes found' : '… homes',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: NyumbaTokens.primaryDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('Sort: Newest'),
                                selected: filters.sortBy == 'newest',
                                onSelected: (_) {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(sortBy: 'newest'),
                                      );
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Sort: Price ↑'),
                                selected: filters.sortBy == 'price_asc',
                                onSelected: (_) {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(sortBy: 'price_asc'),
                                      );
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Verified'),
                                selected: filters.verifiedOnly,
                                onSelected: (v) {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(verifiedOnly: v),
                                      );
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Parking'),
                                selected: filters.requireParking,
                                onSelected: (v) {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(requireParking: v),
                                      );
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Pet friendly'),
                                selected: filters.requirePetFriendly,
                                onSelected: (v) {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(requirePetFriendly: v),
                                      );
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Water'),
                                selected: filters.requireWater,
                                onSelected: (v) {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(requireWater: v),
                                      );
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Security'),
                                selected: filters.requireSecurity,
                                onSelected: (v) {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(requireSecurity: v),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_filtersExpanded) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Bedrooms',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _BrowseChip(
                                label: 'Any',
                                selected: filters.minBedrooms == null,
                                onTap: () {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(clearMinBedrooms: true),
                                      );
                                },
                              ),
                              for (final beds in const [1, 2, 3, 4])
                                _BrowseChip(
                                  label: beds == 4 ? '4+' : '$beds+',
                                  selected: filters.minBedrooms == beds,
                                  onTap: () {
                                    ref.read(searchFiltersProvider.notifier).update(
                                          (f) => f.copyWith(minBedrooms: beds),
                                        );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Max rent (KES / mo)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _BrowseChip(
                                label: 'Any',
                                selected: filters.maxRent == null,
                                onTap: () {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(clearMaxRent: true),
                                      );
                                },
                              ),
                              for (final cap in const [
                                30000,
                                50000,
                                80000,
                                120000,
                                200000,
                              ])
                                _BrowseChip(
                                  label: _formatKes(cap),
                                  selected: filters.maxRent == cap,
                                  onTap: () {
                                    ref.read(searchFiltersProvider.notifier).update(
                                          (f) => f.copyWith(maxRent: cap),
                                        );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                _controller.clear();
                                ref.read(searchFiltersProvider.notifier).state =
                                    const SearchFilters();
                              },
                              child: const Text('Clear all filters'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _BrowseChip(
                                label: 'All',
                                selected: filters.pricingMode == null,
                                onTap: () {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(clearPricingMode: true),
                                      );
                                },
                              ),
                              _BrowseChip(
                                label: 'For rent',
                                selected: filters.pricingMode == 'rent',
                                onTap: () {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(pricingMode: 'rent'),
                                      );
                                },
                              ),
                              _BrowseChip(
                                label: 'For sale',
                                selected: filters.pricingMode == 'sale',
                                onTap: () {
                                  ref.read(searchFiltersProvider.notifier).update(
                                        (f) => f.copyWith(pricingMode: 'sale'),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final t in kPropertyTypes)
                                _BrowseChip(
                                  label: t.label == 'Any type' ? 'All types' : t.label,
                                  selected: filters.type == t.value &&
                                      (t.value != null || filters.type == null),
                                  onTap: () {
                                    ref.read(searchFiltersProvider.notifier).update(
                                          (f) => t.value == null
                                              ? f.copyWith(clearType: true)
                                              : f.copyWith(type: t.value),
                                        );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AsyncSliverBody(
              async: async,
              onRetry: () => ref.invalidate(searchListingsProvider),
              data: (page) {
                if (page.items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'No homes match these filters',
                      subtitle:
                          'Try another neighborhood, clear amenity chips, or raise your max rent.',
                      actionLabel: 'Clear filters',
                      onAction: () {
                        _controller.clear();
                        ref.read(searchFiltersProvider.notifier).state =
                            const SearchFilters();
                      },
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 24),
                  sliver: SliverList.separated(
                    itemCount: page.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => PropertyCard(listing: page.items[i]),
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

String _formatKes(int amount) {
  if (amount >= 1000) {
    final k = amount ~/ 1000;
    return '≤ ${k}k';
  }
  return '≤ $amount';
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _BrowseChip extends StatelessWidget {
  const _BrowseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.18)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
