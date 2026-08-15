import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final adminIdentityVerificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json =
      await ref.watch(mobileApiRepositoryProvider).adminIdentityVerifications();
  final raw = json['items'] ?? json['data'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class AdminIdentityVerificationsPage extends ConsumerWidget {
  const AdminIdentityVerificationsPage({super.key});

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    try {
      await ref.read(mobileApiRepositoryProvider).patchAdminIdentityVerification(
        id,
        {'status': status},
      );
      ref.invalidate(adminIdentityVerificationsProvider);
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
        appBar: AppBar(title: const Text('Identity verifications')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(
              loginLocation(from: '/admin/identity-verifications'),
            ),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(adminIdentityVerificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Identity verifications')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminIdentityVerificationsProvider);
          await ref.read(adminIdentityVerificationsProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(adminIdentityVerificationsProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'No identity verifications',
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
                final status = (row['status'] as String?) ?? 'pending';
                final type = (row['verification_type'] as String?) ?? 'identity';
                final profile = row['profile'];
                String name = 'User';
                if (profile is Map) {
                  name = (profile['full_name'] as String?)?.trim().isNotEmpty == true
                      ? profile['full_name'] as String
                      : name;
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$type · $status',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (id.isEmpty) return;
                            _update(context, ref, id, value);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'approved', child: Text('Approve')),
                            PopupMenuItem(value: 'rejected', child: Text('Reject')),
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
