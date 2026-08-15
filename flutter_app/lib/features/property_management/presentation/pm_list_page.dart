import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class PmProperty {
  const PmProperty({
    required this.id,
    required this.name,
    this.address,
    this.unitCount,
  });

  final String id;
  final String name;
  final String? address;
  final int? unitCount;

  factory PmProperty.fromJson(Map<String, dynamic> json) {
    return PmProperty(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?) ??
          (json['title'] as String?) ??
          'Managed property',
      address: (json['address'] as String?) ??
          (json['neighborhood'] as String?) ??
          (json['location'] as String?),
      unitCount: (json['unitCount'] as num?)?.toInt() ??
          (json['unit_count'] as num?)?.toInt() ??
          (json['units_count'] as num?)?.toInt(),
    );
  }
}

final pmPropertiesProvider =
    FutureProvider.autoDispose<List<PmProperty>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).listPmProperties();
  final raw = json['properties'] ?? json['items'] ?? json['data'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => PmProperty.fromJson(Map<String, dynamic>.from(e)))
      .where((p) => p.id.isNotEmpty)
      .toList();
});

class PmListPage extends ConsumerWidget {
  const PmListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property management')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to view managed properties',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(loginLocation(from: '/pm')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(pmPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property management'),
        actions: [
          IconButton(
            tooltip: 'Subscribe',
            onPressed: () => context.push('/pm/subscribe'),
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pm/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pmPropertiesProvider);
          await ref.read(pmPropertiesProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(pmPropertiesProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'No managed properties',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subscribe to Property Management, then add your first property.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/pm/subscribe'),
                    child: const Text('Subscribe'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/pm/new'),
                    child: const Text('Add property'),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = items[i];
                final parts = <String>[
                  if (p.address != null && p.address!.isNotEmpty) p.address!,
                  if (p.unitCount != null) '${p.unitCount} units',
                ];
                return ListTile(
                  leading: const Icon(Icons.domain_outlined),
                  title: Text(p.name),
                  subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/pm/${p.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
