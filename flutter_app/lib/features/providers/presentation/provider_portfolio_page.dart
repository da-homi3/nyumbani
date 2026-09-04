import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/properties/data/listing.dart';
import 'package:nyumbasearch/features/properties/presentation/property_card.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';

final providerPortfolioProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, providerId) async {
  return ref.watch(mobileApiRepositoryProvider).providerPortfolio(providerId);
});

class ProviderPortfolioPage extends ConsumerWidget {
  const ProviderPortfolioPage({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(providerPortfolioProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Provider portfolio')),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(providerPortfolioProvider(providerId)),
        builder: (json) {
          final provider = json['provider'] is Map
              ? Map<String, dynamic>.from(json['provider'] as Map)
              : const <String, dynamic>{};
          final name = provider['name']?.toString() ?? 'Provider';
          final listingCount = (provider['listingCount'] as num?)?.toInt() ?? 0;
          final logoUrl = provider['logoUrl']?.toString();
          final rawListings = json['listings'];
          final listings = rawListings is List
              ? rawListings
                  .whereType<Map>()
                  .map((row) => Listing.fromJson(Map<String, dynamic>.from(row)))
                  .toList()
              : const <Listing>[];

          if (listings.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _ProviderHeader(name: name, logoUrl: logoUrl, listingCount: listingCount),
                const SizedBox(height: 32),
                EmptyState(
                  icon: Icons.home_work_outlined,
                  title: 'No active listings',
                  subtitle: 'This provider has no homes listed right now.',
                  actionLabel: 'Browse all homes',
                  onAction: () => context.go('/search'),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _ProviderHeader(name: name, logoUrl: logoUrl, listingCount: listingCount),
              const SizedBox(height: 16),
              Text('Available homes', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final listing in listings) ...[
                PropertyCard(listing: listing),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProviderHeader extends StatelessWidget {
  const _ProviderHeader({
    required this.name,
    required this.logoUrl,
    required this.listingCount,
  });

  final String name;
  final String? logoUrl;
  final int listingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (logoUrl != null && logoUrl!.isNotEmpty)
          CircleAvatar(backgroundImage: NetworkImage(logoUrl!), radius: 28)
        else
          CircleAvatar(
            radius: 28,
            child: Icon(Icons.apartment, color: theme.colorScheme.primary),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text('$listingCount active listing${listingCount == 1 ? '' : 's'}'),
            ],
          ),
        ),
      ],
    );
  }
}
