import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';

final adminScamReportsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).adminScamReports();
  final raw = json['reports'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class AdminScamReportsPage extends ConsumerWidget {
  const AdminScamReportsPage({super.key});

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    try {
      await ref.read(mobileApiRepositoryProvider).patchAdminScamReport(
            id,
            status: status,
          );
      ref.invalidate(adminScamReportsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scam reports')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/admin/scams')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(adminScamReportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Scam reports')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminScamReportsProvider);
          await ref.read(adminScamReportsProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(adminScamReportsProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyState(
                    icon: Icons.verified_user_outlined,
                    title: 'No scam reports',
                    subtitle: 'Platform is clear — nothing pending in this queue.',
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = items[i];
                final id = r['id']?.toString() ?? '';
                final property = r['property'] is Map
                    ? Map<String, dynamic>.from(r['property'] as Map)
                    : null;
                final title = property?['title'] ?? 'Property';
                final reason = r['reason'] ?? '';
                final status = r['status'] ?? '';
                final pending = status == 'pending' || status.toString().isEmpty;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$reason',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text('$status'),
                              visualDensity: VisualDensity.compact,
                            ),
                            const Spacer(),
                            if (pending) ...[
                              TextButton(
                                onPressed: id.isEmpty
                                    ? null
                                    : () => _setStatus(
                                          context,
                                          ref,
                                          id,
                                          'reviewed',
                                        ),
                                child: const Text('Reviewed'),
                              ),
                              TextButton(
                                onPressed: id.isEmpty
                                    ? null
                                    : () => _setStatus(
                                          context,
                                          ref,
                                          id,
                                          'dismissed',
                                        ),
                                child: const Text('Dismiss'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
