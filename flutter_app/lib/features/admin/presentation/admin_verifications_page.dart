import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final adminVerificationRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json =
      await ref.watch(mobileApiRepositoryProvider).adminVerificationRequests();
  final raw = json['items'] ?? json['data'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class AdminVerificationsPage extends ConsumerWidget {
  const AdminVerificationsPage({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    try {
      await ref.read(mobileApiRepositoryProvider).patchAdminVerificationRequest(
        id,
        {'status': status},
      );
      ref.invalidate(adminVerificationRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is AppFailure ? e.message : 'Update failed.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verification queue')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () =>
                context.push(loginLocation(from: '/admin/verifications')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(adminVerificationRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification queue')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminVerificationRequestsProvider);
          await ref.read(adminVerificationRequestsProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(adminVerificationRequestsProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'No verification requests',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                final row = items[i];
                final id = row['id']?.toString() ?? '';
                final address = (row['property_address'] as String?) ?? 'Request';
                final status = (row['status'] as String?) ?? 'pending';
                final tier = (row['tier'] as String?) ?? '';
                final email = (row['requester_email'] as String?) ?? '';
                final name = (row['requester_name'] as String?) ?? '';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (status.isNotEmpty) status,
                                  if (tier.isNotEmpty) tier,
                                  if (name.isNotEmpty) name,
                                  if (email.isNotEmpty) email,
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (id.isEmpty) return;
                            _updateStatus(context, ref, id, value);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'pending', child: Text('Pending')),
                            PopupMenuItem(
                              value: 'in_progress',
                              child: Text('In progress'),
                            ),
                            PopupMenuItem(
                              value: 'completed',
                              child: Text('Completed'),
                            ),
                            PopupMenuItem(
                              value: 'cancelled',
                              child: Text('Cancelled'),
                            ),
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
