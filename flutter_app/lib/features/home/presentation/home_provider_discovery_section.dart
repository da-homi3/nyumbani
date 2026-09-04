import 'package:flutter/material.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/features/home/data/featured_agencies_providers.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class HomeProviderDiscoverySection extends ConsumerWidget {
  const HomeProviderDiscoverySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(featuredAgenciesProvider);

    return ColoredBox(
      color: const Color(0xFF0B1220),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRUSTED PROVIDERS',
              style: theme.textTheme.labelMedium?.copyWith(
                color: NyumbaTokens.primaryDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Browse agency portfolios',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            AsyncScaffoldBody(
              async: async,
              onRetry: () => ref.invalidate(featuredAgenciesProvider),
              compact: true,
              builder: (agencies) {
                if (agencies.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 148,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: agencies.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final agency = agencies[i];
                      return _AgencyCard(agency: agency);
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

class _AgencyCard extends StatelessWidget {
  const _AgencyCard({required this.agency});

  final FeaturedAgency agency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = agency.listingCount <= 0
        ? 'Verified provider'
        : '${agency.listingCount} live listing${agency.listingCount == 1 ? '' : 's'}';

    return Material(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/provider/${agency.id}'),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (agency.logoUrl != null && agency.logoUrl!.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(agency.logoUrl!),
                      radius: 18,
                    )
                  else
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: NyumbaTokens.primaryDark.withValues(alpha: 0.15),
                      child: const Icon(Icons.apartment, color: NyumbaTokens.primaryDark, size: 18),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      agency.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                countLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View portfolio →',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: NyumbaTokens.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
