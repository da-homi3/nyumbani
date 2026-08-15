import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final adminPendingProvidersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json =
      await ref.watch(mobileApiRepositoryProvider).adminPendingProviders();
  final raw = json['providers'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class AdminPendingProvidersPage extends ConsumerWidget {
  const AdminPendingProvidersPage({super.key});

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    String id,
    String action,
  ) async {
    try {
      await ref.read(mobileApiRepositoryProvider).reviewAdminProvider(
            id,
            action: action,
          );
      ref.invalidate(adminPendingProvidersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Provider $action')),
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
        appBar: AppBar(title: const Text('Pending providers')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () =>
                context.push(loginLocation(from: '/admin/providers')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(adminPendingProvidersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pending providers')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminPendingProvidersProvider);
          await ref.read(adminPendingProvidersProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(adminPendingProvidersProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [Text('No pending providers.')],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = items[i];
                final id = p['id']?.toString() ?? '';
                final name = p['businessName'] ?? p['business_name'] ?? 'Provider';
                final phone = p['phone'] ?? '';
                final cats = p['categories'];
                final catLabel = cats is List ? cats.join(', ') : '';
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
                            if (catLabel.isNotEmpty) catLabel,
                            if (phone.toString().isNotEmpty) phone.toString(),
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
