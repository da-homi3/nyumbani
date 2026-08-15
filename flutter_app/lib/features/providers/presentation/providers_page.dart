import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/providers/presentation/provider_detail_page.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/site_top_bar.dart';

final providersCategoryFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final providersListProvider =
    FutureProvider.autoDispose<List<ServiceProviderItem>>((ref) async {
  final category = ref.watch(providersCategoryFilterProvider);
  final json = await ref.watch(mobileApiRepositoryProvider).listProviders(
        category: category,
      );
  final raw = json['providers'] ?? json['items'] ?? json['data'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => ServiceProviderItem.fromJson(Map<String, dynamic>.from(e)))
      .where((p) => p.id.isNotEmpty)
      .toList();
});

final providerCategoriesListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final json = await ref.watch(mobileApiRepositoryProvider).providerCategories();
    final raw = json['categories'] ?? json['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } catch (_) {
    return const [];
  }
});

class ProvidersPage extends ConsumerWidget {
  const ProvidersPage({super.key});

  static const _fallbackCategories = <({String id, String label, IconData icon, Color glow})>[
    (id: 'electricians', label: 'Electricians', icon: Icons.bolt, glow: Color(0xFFFACC15)),
    (id: 'plumbers', label: 'Plumbers', icon: Icons.plumbing, glow: Color(0xFF38BDF8)),
    (id: 'painters', label: 'Painters & decorators', icon: Icons.format_paint, glow: Color(0xFFF472B6)),
    (id: 'internet', label: 'Internet installation', icon: Icons.wifi, glow: Color(0xFFA78BFA)),
    (id: 'security', label: 'Security systems', icon: Icons.shield_outlined, glow: Color(0xFF2DD4BF)),
    (id: 'movers', label: 'Movers & relocation', icon: Icons.local_shipping_outlined, glow: Color(0xFFFB923C)),
    (id: 'cleaning', label: 'Cleaning services', icon: Icons.auto_awesome, glow: Color(0xFF60A5FA)),
    (id: 'solar', label: 'Solar installation', icon: Icons.wb_sunny_outlined, glow: Color(0xFFFDE047)),
    (id: 'pest', label: 'Pest control & fumigation', icon: Icons.bug_report_outlined, glow: Color(0xFF4ADE80)),
    (id: 'carpentry', label: 'Carpentry', icon: Icons.handyman_outlined, glow: Color(0xFFFB923C)),
  ];

  IconData _iconFor(String id, String label) {
    final key = '${id}_$label'.toLowerCase();
    for (final f in _fallbackCategories) {
      if (key.contains(f.id) || label.toLowerCase().contains(f.label.split(' ').first.toLowerCase())) {
        return f.icon;
      }
    }
    return Icons.handyman_outlined;
  }

  Color _glowFor(String id, String label) {
    final key = '${id}_$label'.toLowerCase();
    for (final f in _fallbackCategories) {
      if (key.contains(f.id)) return f.glow;
    }
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(providersListProvider);
    final catsAsync = ref.watch(providerCategoriesListProvider);
    final selected = ref.watch(providersCategoryFilterProvider);
    final bottomPad = NyumbaTokens.shellBottomInset(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(providersListProvider);
          ref.invalidate(providerCategoriesListProvider);
          await ref.read(providersListProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const ContainedSliver(child: SiteTopBarSolid()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VERIFIED HOME SERVICES',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF22C55E),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Everything your new home needs',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trusted service providers across Kenya — browse by category and filter by county.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => context.push('/services/me'),
                          icon: const Icon(Icons.storefront_outlined, size: 18),
                          label: const Text('My profile'),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/services/register'),
                          icon: const Icon(Icons.add_business_outlined, size: 18),
                          label: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: catsAsync.when(
                data: (cats) {
                  final items = cats.isNotEmpty
                      ? cats
                      : _fallbackCategories
                          .map((e) => {'id': e.id, 'label': e.label, 'count': 0})
                          .toList();
                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.25,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final c = items[index];
                        final id = c['id']?.toString() ?? '';
                        final label = (c['label'] as String?) ?? id;
                        final count = (c['count'] as num?)?.toInt() ??
                            (c['providers'] as num?)?.toInt();
                        final selectedHere = selected == id;
                        final glow = _glowFor(id, label);
                        return Material(
                          color: selectedHere
                              ? theme.colorScheme.primary.withValues(alpha: 0.12)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              ref.read(providersCategoryFilterProvider.notifier).state =
                                  selectedHere ? null : id;
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          glow.withValues(alpha: 0.35),
                                          glow.withValues(alpha: 0.05),
                                        ],
                                      ),
                                    ),
                                    child: Icon(_iconFor(id, label), color: glow, size: 22),
                                  ),
                                  const Spacer(),
                                  Text(
                                    label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    count == null ? 'Browse providers' : '$count providers',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  selected == null ? 'All providers' : 'Providers in category',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            AsyncSliverBody(
              async: async,
              onRetry: () => ref.invalidate(providersListProvider),
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
                      child: Text(
                        selected == null
                            ? 'Service providers in your area will appear here.'
                            : 'No providers in this category yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPad),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = items[index];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                          [
                            if ((p.category ?? '').isNotEmpty) p.category!,
                            if ((p.neighborhood ?? '').isNotEmpty) p.neighborhood!,
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/services/${p.id}'),
                      );
                    },
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

/// Tiny helper so SafeArea top bar sits in a sliver.
class ContainedSliver extends StatelessWidget {
  const ContainedSliver({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: child);
  }
}
