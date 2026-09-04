import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';
import 'package:nyumbasearch/shared/widgets/motion.dart';
import 'package:nyumbasearch/shared/widgets/portal_scaffold.dart';

class LandlordDashboardStats {
  const LandlordDashboardStats({
    required this.totalProperties,
    required this.activeProperties,
    required this.vacantProperties,
    required this.totalViews,
    required this.totalLeads,
    required this.newLeads,
    required this.potentialRevenue,
  });

  final int totalProperties;
  final int activeProperties;
  final int vacantProperties;
  final int totalViews;
  final int totalLeads;
  final int newLeads;
  final int potentialRevenue;

  factory LandlordDashboardStats.fromJson(Map<String, dynamic> json) {
    final s = json['stats'] is Map
        ? Map<String, dynamic>.from(json['stats'] as Map)
        : json;
    return LandlordDashboardStats(
      totalProperties: (s['totalProperties'] as num?)?.toInt() ?? 0,
      activeProperties: (s['activeProperties'] as num?)?.toInt() ?? 0,
      vacantProperties: (s['vacantProperties'] as num?)?.toInt() ?? 0,
      totalViews: (s['totalViews'] as num?)?.toInt() ?? 0,
      totalLeads: (s['totalLeads'] as num?)?.toInt() ?? 0,
      newLeads: (s['newLeads'] as num?)?.toInt() ?? 0,
      potentialRevenue: (s['potentialRevenue'] as num?)?.toInt() ?? 0,
    );
  }
}

final landlordDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(mobileApiRepositoryProvider).landlordDashboard();
});

const _landlordNav = <PortalNavItem>[
  PortalNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/landlord'),
  PortalNavItem(icon: Icons.home_work_outlined, label: 'Properties', path: '/landlord/listings'),
  PortalNavItem(icon: Icons.insights_outlined, label: 'Analytics', path: '/landlord/analytics'),
  PortalNavItem(icon: Icons.bolt_outlined, label: 'Boost', path: '/landlord/boost'),
  PortalNavItem(icon: Icons.key_outlined, label: 'Caretakers', path: '/landlord/caretakers'),
  PortalNavItem(icon: Icons.card_giftcard_outlined, label: 'Lead packs', path: '/landlord/leads'),
  PortalNavItem(icon: Icons.description_outlined, label: 'Applications', path: '/landlord/applications'),
  PortalNavItem(icon: Icons.calendar_month_outlined, label: 'Viewings', path: '/landlord/viewings'),
  PortalNavItem(icon: Icons.workspace_premium_outlined, label: 'Plan', path: '/landlord/plan'),
  PortalNavItem(icon: Icons.payments_outlined, label: 'Billing', path: '/billing'),
  PortalNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Payouts', path: '/landlord/payouts'),
  PortalNavItem(icon: Icons.upload_file_outlined, label: 'Import', path: '/landlord/import'),
  PortalNavItem(icon: Icons.hub_outlined, label: 'Integrations', path: '/landlord/integrations'),
];

class LandlordDashboardPage extends ConsumerWidget {
  const LandlordDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Landlord')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/landlord')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(landlordDashboardProvider);

    return PortalShell(
      portalLabel: 'Landlord portal',
      title: 'Welcome back, landlord',
      navItems: _landlordNav,
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined, size: 16),
          label: const Text('Settings'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => context.push('/landlord/listings/new'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add property'),
        ),
        const SizedBox(width: 8),
      ],
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(landlordDashboardProvider),
        builder: (json) {
          final stats = LandlordDashboardStats.fromJson(json);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(landlordDashboardProvider);
              await ref.read(landlordDashboardProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  'OVERVIEW',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 520;
                    final metrics = <(String, String, String, IconData)>[
                      (
                        'Total Properties',
                        '${stats.totalProperties}',
                        '${stats.activeProperties} active · ${stats.vacantProperties} vacant',
                        Icons.description_outlined,
                      ),
                      (
                        'Property Views',
                        '${stats.totalViews}',
                        'last 30 days',
                        Icons.visibility_outlined,
                      ),
                      (
                        'Tenant Leads',
                        '${stats.totalLeads}',
                        '${stats.newLeads} new',
                        Icons.groups_outlined,
                      ),
                      (
                        'Monthly Revenue',
                        'KES ${_fmt(stats.potentialRevenue)}',
                        'potential',
                        Icons.trending_up,
                      ),
                    ];
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < metrics.length; i++)
                          SizedBox(
                            width: wide
                                ? (constraints.maxWidth - 10) / 2
                                : constraints.maxWidth,
                            child: ScrollReveal(
                              delay: Duration(milliseconds: 40 * i),
                              child: PortalMetricCard(
                                label: metrics[i].$1,
                                value: metrics[i].$2,
                                subtitle: metrics[i].$3,
                                icon: metrics[i].$4,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick actions',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.add_home_work_outlined, size: 16),
                      label: const Text('Add property'),
                      onPressed: () => context.push('/landlord/listings/new'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.bolt_outlined, size: 16),
                      label: const Text('Boost listing'),
                      onPressed: () => context.push('/landlord/boost'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.key_outlined, size: 16),
                      label: const Text('Caretakers'),
                      onPressed: () => context.push('/landlord/caretakers'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.upload_file_outlined, size: 16),
                      label: const Text('Import CSV'),
                      onPressed: () => context.push('/landlord/import'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.apartment_outlined, size: 16),
                      label: const Text('Property management'),
                      onPressed: () => context.push('/pm'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: NyumbaTokens.borderRadiusLg,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.key, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add caretaker PINs so staff can help on-site.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/landlord/caretakers'),
                        child: const Text('Manage →'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Your properties',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/landlord/listings'),
                      child: const Text('Manage all →'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (stats.totalProperties == 0)
                  EmptyState(
                    compact: true,
                    icon: Icons.home_work_outlined,
                    title: 'No properties yet',
                    subtitle: 'List your first home to start getting verified tenant leads.',
                    actionLabel: 'Add property',
                    onAction: () => context.push('/landlord/listings/new'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => context.push('/landlord/listings'),
                    icon: const Icon(Icons.grid_view),
                    label: Text(
                      'Open properties grid · ${stats.totalProperties} listed',
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

class LandlordSkeleton extends StatelessWidget {
  const LandlordSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1F2937),
      highlightColor: const Color(0xFF374151),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          4,
          (_) => Container(
            height: 96,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
