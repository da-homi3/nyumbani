import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/viewings/data/viewings_providers.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';
import 'package:nyumbasearch/shared/widgets/portal_scaffold.dart';

const landlordPortalNav = <PortalNavItem>[
  PortalNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/landlord'),
  PortalNavItem(icon: Icons.home_work_outlined, label: 'Properties', path: '/landlord/listings'),
  PortalNavItem(icon: Icons.description_outlined, label: 'Applications', path: '/landlord/applications'),
  PortalNavItem(icon: Icons.calendar_month_outlined, label: 'Viewings', path: '/landlord/viewings'),
  PortalNavItem(icon: Icons.insights_outlined, label: 'Analytics', path: '/landlord/analytics'),
];

class LandlordViewingsPage extends ConsumerWidget {
  const LandlordViewingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Viewings')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/landlord/viewings')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(landlordViewingsProvider);

    return PortalShell(
      portalLabel: 'Landlord portal',
      title: 'Viewing requests',
      navItems: landlordPortalNav,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(landlordViewingsProvider),
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(landlordViewingsProvider),
          builder: (viewings) {
            if (viewings.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 48),
                  EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'No viewing requests',
                    subtitle: 'Tenants who book viewings on your listings appear here.',
                    actionLabel: 'View listings',
                    onAction: () => context.push('/landlord/listings'),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: viewings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final viewing = viewings[i];
                final property = viewing['properties'] is Map
                    ? Map<String, dynamic>.from(viewing['properties'] as Map)
                    : const <String, dynamic>{};
                final tenant = viewing['tenant_profile'] is Map
                    ? Map<String, dynamic>.from(viewing['tenant_profile'] as Map)
                    : const <String, dynamic>{};
                final title = property['title']?.toString() ?? 'Listing';
                final tenantName = tenant['full_name']?.toString() ?? 'Tenant';
                final phone = tenant['phone']?.toString();
                final status = viewing['status']?.toString() ?? 'pending';
                final scheduledAt = viewing['scheduled_at']?.toString() ?? '';
                final viewingId = viewing['id']?.toString();
                final propertyId = property['id']?.toString();
                final locked = viewing['leadContactsLocked'] == true;

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
                              label: Text(formatViewingStatus(status)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        Text(title, style: theme.textTheme.bodyMedium),
                        if (scheduledAt.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(scheduledAt.replaceFirst('T', ' · ').split('.').first),
                          ),
                        if (phone != null && phone.isNotEmpty && !locked)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Phone: $phone'),
                          )
                        else if (locked)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Upgrade lead access to view tenant phone.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        if (viewingId != null && status != 'cancelled' && status != 'completed') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: status,
                            decoration: const InputDecoration(labelText: 'Update status'),
                            items: const [
                              DropdownMenuItem(value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                              DropdownMenuItem(value: 'completed', child: Text('Completed')),
                              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                            ],
                            onChanged: (next) async {
                              if (next == null) return;
                              try {
                                await ref.read(mobileApiRepositoryProvider).updateViewingStatus(
                                      viewingId: viewingId,
                                      status: next,
                                    );
                                ref.invalidate(landlordViewingsProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Viewing updated.')),
                                  );
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e is AppFailure
                                          ? e.message
                                          : 'Could not update viewing.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
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
