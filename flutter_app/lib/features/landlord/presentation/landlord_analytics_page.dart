import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final landlordAnalyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(mobileApiRepositoryProvider).landlordAnalytics();
});

class LandlordAnalyticsPage extends ConsumerWidget {
  const LandlordAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () =>
                context.push(loginLocation(from: '/landlord/analytics')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(landlordAnalyticsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(landlordAnalyticsProvider);
          await ref.read(landlordAnalyticsProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(landlordAnalyticsProvider),
          builder: (json) {
            final summary = json['summary'] is Map
                ? Map<String, dynamic>.from(json['summary'] as Map)
                : <String, dynamic>{};
            final top = json['topListings'] is List
                ? (json['topListings'] as List)
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : <Map<String, dynamic>>[];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Chip(label: Text('Views: ${summary['totalViews'] ?? 0}')),
                    Chip(label: Text('Leads: ${summary['totalLeads'] ?? 0}')),
                    Chip(label: Text('Active: ${summary['activeProperties'] ?? 0}')),
                    Chip(
                      label: Text(
                        'Potential: KES ${summary['potentialRevenue'] ?? 0}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Top listings by views',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (top.isEmpty)
                  const Text('No listing data yet.')
                else
                  ...top.map((p) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text((p['title'] as String?) ?? 'Listing'),
                      subtitle: Text(
                        '${p['views'] ?? 0} views · ${p['leads'] ?? 0} leads',
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
