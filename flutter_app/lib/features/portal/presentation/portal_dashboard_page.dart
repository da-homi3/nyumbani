import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/landlord/presentation/landlord_dashboard_page.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/portal_scaffold.dart';

final agencyDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(mobileApiRepositoryProvider).agencyDashboard();
});

final managerDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(mobileApiRepositoryProvider).managerDashboard();
});

List<PortalNavItem> portalRoleNav(String portal) {
  final teamPath = '/$portal/team';
  return [
    PortalNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/$portal'),
    PortalNavItem(
      icon: Icons.home_work_outlined,
      label: 'Properties',
      path: '/$portal/listings',
    ),
    PortalNavItem(
      icon: Icons.insights_outlined,
      label: 'Analytics',
      path: '/$portal/analytics',
    ),
    PortalNavItem(
      icon: Icons.apartment_outlined,
      label: 'Manage',
      path: '/$portal/pm',
    ),
    PortalNavItem(icon: Icons.groups_outlined, label: 'Team', path: teamPath),
    PortalNavItem(
      icon: Icons.chat_bubble_outline,
      label: 'Messages',
      path: '/$portal/messages',
    ),
    PortalNavItem(
      icon: Icons.payments_outlined,
      label: 'Billing',
      path: '/$portal/billing',
    ),
    PortalNavItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Payouts',
      path: '/$portal/payouts',
    ),
    PortalNavItem(
      icon: Icons.upload_file_outlined,
      label: 'Import',
      path: '/$portal/import',
    ),
    PortalNavItem(
      icon: Icons.hub_outlined,
      label: 'Integrations',
      path: '/$portal/integrations',
    ),
  ];
}

class PortalDashboardPage extends ConsumerWidget {
  const PortalDashboardPage({
    super.key,
    required this.portal,
    required this.title,
    required this.teamPath,
  });

  final String portal;
  final String title;
  final String teamPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);
    final nav = portalRoleNav(portal);

    if (session == null) {
      return PortalShell(
        portalLabel: title,
        title: title,
        navItems: nav,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/$portal')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = portal == 'agency'
        ? ref.watch(agencyDashboardProvider)
        : ref.watch(managerDashboardProvider);

    return PortalShell(
      portalLabel: title,
      title: 'Dashboard',
      navItems: nav,
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () {
          if (portal == 'agency') {
            ref.invalidate(agencyDashboardProvider);
          } else {
            ref.invalidate(managerDashboardProvider);
          }
        },
        builder: (json) {
          final stats = LandlordDashboardStats.fromJson(json);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Overview',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  PortalStatChip(label: 'Listings', value: '${stats.totalProperties}'),
                  PortalStatChip(label: 'Active', value: '${stats.activeProperties}'),
                  PortalStatChip(label: 'Vacant', value: '${stats.vacantProperties}'),
                  PortalStatChip(label: 'Views', value: '${stats.totalViews}'),
                  PortalStatChip(label: 'Leads', value: '${stats.totalLeads}'),
                  PortalStatChip(
                    label: 'Potential rent',
                    value: 'KES ${stats.potentialRevenue}',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Shortcuts',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              PortalNavTile(
                icon: Icons.home_work_outlined,
                title: 'Listings',
                onTap: () => context.push('/$portal/listings'),
              ),
              PortalNavTile(
                icon: Icons.insights_outlined,
                title: 'Analytics',
                onTap: () => context.push('/$portal/analytics'),
              ),
              PortalNavTile(
                icon: Icons.apartment_outlined,
                title: 'Property management',
                onTap: () => context.push('/$portal/pm'),
              ),
              PortalNavTile(
                icon: Icons.groups_outlined,
                title: 'Team',
                onTap: () => context.push(teamPath),
              ),
              PortalNavTile(
                icon: Icons.chat_bubble_outline,
                title: 'Leads / messages',
                onTap: () => context.push('/$portal/messages'),
              ),
              PortalNavTile(
                icon: Icons.receipt_long_outlined,
                title: 'Billing',
                onTap: () => context.push('/$portal/billing'),
              ),
              PortalNavTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payouts',
                onTap: () => context.push('/$portal/payouts'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AgencyDashboardPage extends StatelessWidget {
  const AgencyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalDashboardPage(
      portal: 'agency',
      title: 'Agency',
      teamPath: '/agency/team',
    );
  }
}

class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalDashboardPage(
      portal: 'manager',
      title: 'Manager',
      teamPath: '/manager/team',
    );
  }
}
