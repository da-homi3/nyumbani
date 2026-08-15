import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final adminListingsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).adminListProperties();
  final raw = json['properties'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class AdminListingsPage extends ConsumerWidget {
  const AdminListingsPage({super.key});

  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool isActive,
  ) async {
    try {
      await ref.read(mobileApiRepositoryProvider).adminSetPropertyActive(
            id,
            isActive: isActive,
          );
      ref.invalidate(adminListingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isActive ? 'Activated' : 'Deactivated')),
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
        appBar: AppBar(title: const Text('Listing moderation')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () =>
                context.push(loginLocation(from: '/admin/listings')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(adminListingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing moderation'),
        actions: [
          IconButton(
            tooltip: 'Create listing',
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/listings/new'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminListingsProvider);
          await ref.read(adminListingsProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(adminListingsProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [Text('No listings found.')],
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
                final title = (p['title'] as String?) ?? 'Listing';
                final hood = (p['neighborhood'] as String?) ?? '';
                final active = p['is_active'] == true || p['isActive'] == true;
                final verified =
                    p['is_verified'] == true || p['isVerified'] == true;
                final rent = (p['rent_kes'] as num?)?.toInt() ??
                    (p['rentKes'] as num?)?.toInt();
                final score = (p['authenticity_score'] as num?)?.toInt() ??
                    (p['authenticityScore'] as num?)?.toInt();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              active
                                  ? Icons.home_work_outlined
                                  : Icons.home_outlined,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (hood.isNotEmpty) hood,
                                      if (rent != null) 'KES $rent',
                                      active ? 'active' : 'inactive',
                                      if (verified) 'verified',
                                      if (score != null) 'trust $score',
                                    ].join(' · '),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: active,
                              onChanged: id.isEmpty
                                  ? null
                                  : (v) => _setActive(context, ref, id, v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip: 'Trust −5',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: id.isEmpty
                                  ? null
                                  : () async {
                                      try {
                                        await ref
                                            .read(mobileApiRepositoryProvider)
                                            .adminAdjustAuthenticity(id, delta: -5);
                                        ref.invalidate(adminListingsProvider);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e is AppFailure
                                                    ? e.message
                                                    : 'Failed',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                            ),
                            IconButton(
                              tooltip: 'Trust +5',
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: id.isEmpty
                                  ? null
                                  : () async {
                                      try {
                                        await ref
                                            .read(mobileApiRepositoryProvider)
                                            .adminAdjustAuthenticity(id, delta: 5);
                                        ref.invalidate(adminListingsProvider);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e is AppFailure
                                                    ? e.message
                                                    : 'Failed',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                            ),
                            IconButton(
                              tooltip: verified ? 'Unverify' : 'Verify',
                              icon: Icon(
                                verified
                                    ? Icons.verified
                                    : Icons.verified_outlined,
                              ),
                              onPressed: id.isEmpty
                                  ? null
                                  : () async {
                                      try {
                                        await ref
                                            .read(mobileApiRepositoryProvider)
                                            .adminSetPropertyVerified(
                                              id,
                                              isVerified: !verified,
                                            );
                                        ref.invalidate(adminListingsProvider);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e is AppFailure
                                                    ? e.message
                                                    : 'Failed',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
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
