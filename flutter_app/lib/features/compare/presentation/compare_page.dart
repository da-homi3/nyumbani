import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/compare/data/compare_controller.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final compareListingsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final ids = ref.watch(compareIdsProvider);
  if (ids.length < 2) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).compareListings(ids);
  final raw = json['items'] ?? json['properties'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class ComparePage extends ConsumerWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(compareIdsProvider);
    final theme = Theme.of(context);

    if (ids.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compare homes')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add 2–4 homes to compare',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Open a listing and tap the compare icon. Currently ${ids.length} selected.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/search'),
                child: const Text('Browse listings'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(compareListingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare homes'),
        actions: [
          TextButton(
            onPressed: () => ref.read(compareIdsProvider.notifier).clear(),
            child: const Text('Clear'),
          ),
        ],
      ),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(compareListingsProvider),
        builder: (items) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in items)
                      SizedBox(
                        width: 220,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (p['title'] as String?) ?? 'Home',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text((p['neighborhood'] as String?) ?? '—'),
                                Text('KES ${(p['rent_kes'] as num?)?.toInt() ?? (p['rentKes'] as num?)?.toInt() ?? 0}'),
                                Text('${p['bedrooms'] ?? '—'} beds · ${p['bathrooms'] ?? '—'} baths'),
                                Text((p['property_type'] as String?) ??
                                    (p['propertyType'] as String?) ??
                                    '—'),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () =>
                                      context.push('/property/${p['id']}'),
                                  child: const Text('Open'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
