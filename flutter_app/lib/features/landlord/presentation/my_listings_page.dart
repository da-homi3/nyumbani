import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';
import 'package:nyumbasearch/shared/widgets/motion.dart';
import 'package:nyumbasearch/shared/widgets/portal_scaffold.dart';

class OwnerProperty {
  const OwnerProperty({
    required this.id,
    required this.title,
    this.neighborhood,
    this.status,
    this.rentKes,
    this.imageUrl,
    this.scoreLabel,
  });

  final String id;
  final String title;
  final String? neighborhood;
  final String? status;
  final int? rentKes;
  final String? imageUrl;
  final String? scoreLabel;

  factory OwnerProperty.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    String? image;
    if (images is List && images.isNotEmpty) {
      image = images.first.toString();
    }
    image ??= (json['primary_image'] as String?) ?? (json['image'] as String?);
    final score = (json['authenticity_score'] as num?)?.toInt();
    return OwnerProperty(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?) ?? 'Untitled',
      neighborhood: (json['neighborhood'] as String?) ??
          (json['location'] as String?),
      status: (json['status'] as String?) ??
          (json['is_vacant'] == true
              ? 'vacant'
              : json['is_vacant'] == false
                  ? 'occupied'
                  : null),
      rentKes: (json['rent_kes'] as num?)?.toInt() ??
          (json['rentKes'] as num?)?.toInt(),
      imageUrl: image,
      scoreLabel: score == null ? null : 'A-$score',
    );
  }
}

final ownerPropertiesProvider =
    FutureProvider.autoDispose<List<OwnerProperty>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).listProperties();
  final raw = json['properties'] ?? json['items'] ?? json['data'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => OwnerProperty.fromJson(Map<String, dynamic>.from(e)))
      .where((p) => p.id.isNotEmpty)
      .toList();
});

const _landlordNav = <PortalNavItem>[
  PortalNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/landlord'),
  PortalNavItem(icon: Icons.home_work_outlined, label: 'Properties', path: '/landlord/listings'),
  PortalNavItem(icon: Icons.insights_outlined, label: 'Analytics', path: '/landlord/analytics'),
  PortalNavItem(icon: Icons.bolt_outlined, label: 'Boost', path: '/landlord/boost'),
  PortalNavItem(icon: Icons.key_outlined, label: 'Caretakers', path: '/landlord/caretakers'),
  PortalNavItem(icon: Icons.workspace_premium_outlined, label: 'Plan', path: '/landlord/plan'),
  PortalNavItem(icon: Icons.payments_outlined, label: 'Billing', path: '/billing'),
];

class MyListingsPage extends ConsumerWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Properties')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () =>
                context.push(loginLocation(from: '/landlord/listings')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(ownerPropertiesProvider);

    return PortalShell(
      portalLabel: 'Landlord portal',
      title: 'Properties',
      navItems: _landlordNav,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/landlord/listings/new'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add property'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ownerPropertiesProvider);
          await ref.read(ownerPropertiesProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(ownerPropertiesProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyState(
                    icon: Icons.home_work_outlined,
                    title: 'No listings yet',
                    subtitle:
                        'Create your first property to start receiving verified tenant leads.',
                    actionLabel: 'Create listing',
                    onAction: () => context.push('/landlord/listings/new'),
                  ),
                ],
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: wide ? 2 : 1,
                    mainAxisExtent: wide ? 300 : 320,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return ScrollReveal(
                      delay: Duration(milliseconds: 40 * (i % 6)),
                      child: _OwnerPropertyCard(property: p),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _OwnerPropertyCard extends StatelessWidget {
  const _OwnerPropertyCard({required this.property});
  final OwnerProperty property;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vacant = property.status?.toLowerCase() == 'vacant';
    return TiltCard(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: NyumbaTokens.borderRadiusLg,
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  property.imageUrl == null || property.imageUrl!.isEmpty
                      ? ColoredBox(
                          color: theme.colorScheme.surface,
                          child: const Icon(Icons.home_work_outlined, size: 40),
                        )
                      : CachedNetworkImage(
                          imageUrl: property.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Shimmer.fromColors(
                            baseColor: const Color(0xFF1F2937),
                            highlightColor: const Color(0xFF374151),
                            child: const ColoredBox(color: Colors.white),
                          ),
                        ),
                  if (property.scoreLabel != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          property.scoreLabel!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if ((property.neighborhood ?? '').isNotEmpty) property.neighborhood!,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (property.rentKes != null)
                          Text(
                            'KES ${property.rentKes}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: NyumbaTokens.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        const Spacer(),
                        if (property.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: vacant
                                  ? const Color(0xFFD97706).withValues(alpha: 0.2)
                                  : NyumbaTokens.primaryDark.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              vacant ? 'Vacant' : 'Active',
                              style: TextStyle(
                                color: vacant
                                    ? const Color(0xFFFB923C)
                                    : NyumbaTokens.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                context.push('/landlord/listings/${property.id}/edit'),
                            child: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(
                              '/landlord/boost?propertyId=${property.id}',
                            ),
                            icon: const Icon(Icons.bolt, size: 16),
                            label: const Text('Boost'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push('/property/${property.id}'),
                            child: const Text('View'),
                          ),
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
    );
  }
}
