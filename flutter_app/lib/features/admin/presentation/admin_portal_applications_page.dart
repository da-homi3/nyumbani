import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';

final adminPortalApplicationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json =
      await ref.watch(mobileApiRepositoryProvider).adminPortalApplications();
  final raw = json['applications'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class AdminPortalApplicationsPage extends ConsumerWidget {
  const AdminPortalApplicationsPage({super.key});

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    String id,
    String action,
  ) async {
    try {
      await ref.read(mobileApiRepositoryProvider).reviewAdminPortalApplication(
            id,
            action: action,
          );
      ref.invalidate(adminPortalApplicationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application $action')),
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
        appBar: AppBar(title: const Text('Portal applications')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () =>
                context.push(loginLocation(from: '/admin/applications')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(adminPortalApplicationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Portal applications')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminPortalApplicationsProvider);
          await ref.read(adminPortalApplicationsProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(adminPortalApplicationsProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No pending applications',
                    subtitle: 'New landlord, agency, and manager requests will land here.',
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
                final app = items[i];
                final profile = app['profile'] is Map
                    ? Map<String, dynamic>.from(app['profile'] as Map)
                    : null;
                final name = profile?['full_name'] ??
                    profile?['fullName'] ??
                    app['organizationName'] ??
                    'Applicant';
                final role = app['requestedRole'] ?? app['requested_role'] ?? '';
                final phone = app['phone'] ?? profile?['phone'] ?? '';
                final id = app['id']?.toString() ?? '';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (role.toString().isNotEmpty) role.toString(),
                            if (phone.toString().isNotEmpty) phone.toString(),
                            if ((app['organizationName'] as String?)?.isNotEmpty == true)
                              app['organizationName'],
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: id.isEmpty
                                  ? null
                                  : () => _review(context, ref, id, 'approve'),
                              child: const Text('Approve'),
                            ),
                            TextButton(
                              onPressed: id.isEmpty
                                  ? null
                                  : () => _review(context, ref, id, 'reject'),
                              child: const Text('Reject'),
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
