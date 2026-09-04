import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/applications/data/tenant_applications_providers.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';
import 'package:nyumbasearch/shared/widgets/portal_scaffold.dart';
import 'package:nyumbasearch/features/landlord/presentation/landlord_viewings_page.dart';

List<Map<String, dynamic>> _parseLandlordApplications(Map<String, dynamic> json) {
  final raw = json['applications'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}

final landlordApplicationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).listLandlordApplications();
  return _parseLandlordApplications(json);
});

const _landlordApplicationsNav = landlordPortalNav;

class LandlordApplicationsPage extends ConsumerWidget {
  const LandlordApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Applications')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/landlord/applications')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(landlordApplicationsProvider);

    return PortalShell(
      portalLabel: 'Landlord portal',
      title: 'Rental applications',
      navItems: _landlordApplicationsNav,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(landlordApplicationsProvider),
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(landlordApplicationsProvider),
          builder: (apps) {
            if (apps.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 48),
                  EmptyState(
                    icon: Icons.description_outlined,
                    title: 'No applications yet',
                    subtitle: 'Tenants who tap Apply on your listings appear here.',
                    actionLabel: 'View listings',
                    onAction: () => context.push('/landlord/listings'),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final app = apps[i];
                final property = app['property'] is Map
                    ? Map<String, dynamic>.from(app['property'] as Map)
                    : const <String, dynamic>{};
                final tenant = app['tenant_profile'] is Map
                    ? Map<String, dynamic>.from(app['tenant_profile'] as Map)
                    : const <String, dynamic>{};
                final title = property['title']?.toString() ?? 'Listing';
                final tenantName = tenant['full_name']?.toString() ?? 'Tenant applicant';
                final phone = tenant['phone']?.toString();
                final status = app['status']?.toString() ?? 'submitted';
                final score = app['tenant_score_percent'];
                final message = app['message']?.toString();
                final propertyId = property['id']?.toString();
                final applicationId = app['id']?.toString();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tenantName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(formatApplicationStatus(status)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        Text(title, style: theme.textTheme.bodyMedium),
                        if (score != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Profile score: $score%'),
                          ),
                        if (message != null && message.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(message),
                        ],
                        if (phone != null && phone.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Phone: $phone'),
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: status == 'submitted' ? 'under_review' : status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: 'under_review', child: Text('Under review')),
                            DropdownMenuItem(value: 'approved', child: Text('Approved')),
                            DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                          ],
                          onChanged: status == 'withdrawn' || applicationId == null
                              ? null
                              : (next) async {
                                  if (next == null) return;
                                  try {
                                    await ref
                                        .read(mobileApiRepositoryProvider)
                                        .reviewLandlordApplication(
                                          applicationId,
                                          status: next,
                                        );
                                    ref.invalidate(landlordApplicationsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Application updated.')),
                                      );
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e is AppFailure
                                              ? e.message
                                              : 'Could not update application.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        ),
                        if (propertyId != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => context.push('/property/$propertyId'),
                            child: const Text('View listing'),
                          ),
                        ],
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
