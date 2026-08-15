import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/brand_logo.dart';
import 'package:nyumbasearch/shared/widgets/motion.dart';
import 'package:nyumbasearch/shared/widgets/portal_scaffold.dart';

class AdminSummary {
  const AdminSummary({required this.counts});

  final Map<String, int> counts;

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['counts'] ?? json['summary'] ?? json;
    final map = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final v = entry.value;
        if (v is num) {
          map[entry.key.toString()] = v.toInt();
        }
      }
    }
    return AdminSummary(counts: map);
  }

  int of(String key) => counts[key] ?? 0;
}

final adminSummaryProvider = FutureProvider.autoDispose<AdminSummary>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).adminSummary();
  return AdminSummary.fromJson(json);
});

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  var _tab = 0;

  static const _tabs = <({String label, String path, String? countKey})>[
    (label: 'Verification Queue', path: '/admin/verifications', countKey: null),
    (label: 'Property checks', path: '/admin/identity-verifications', countKey: null),
    (label: 'Analytics', path: '/admin', countKey: null),
    (label: 'Scam Reports', path: '/admin/scams', countKey: 'scamReports'),
    (label: 'Moderate listings', path: '/admin/listings', countKey: 'pendingListings'),
    (label: 'Audit Logs', path: '/admin', countKey: 'auditLogs'),
    (label: 'Portal applications', path: '/admin/applications', countKey: 'portalApplications'),
    (label: 'Service providers', path: '/admin/providers', countKey: 'pendingProviders'),
    (label: 'PM oversight', path: '/admin/pm', countKey: null),
    (label: 'Revenue', path: '/admin/revenue', countKey: null),
    (label: 'Announcements', path: '/admin/announcements', countKey: null),
    (label: 'Founding promo', path: '/admin/promo', countKey: null),
    (label: 'Advertise review', path: '/admin/advertise', countKey: null),
  ];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return PortalScaffold(
        title: 'Admin',
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/admin')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(adminSummaryProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const BrandLogo(height: 28, markOnly: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Admin Control Center',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: const Text('Settings'),
                  ),
                ],
              ),
            ),
          ),
          Text(
            'Logged in as Administrator',
            textAlign: TextAlign.right,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: async.when(
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
              data: (summary) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _tabs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final t = _tabs[i];
                    final selected = _tab == i;
                    final badge = t.countKey == null ? null : summary.of(t.countKey!);
                    return ChoiceChip(
                      selected: selected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.label),
                          if (badge != null && badge > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$badge',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onSelected: (_) {
                        setState(() => _tab = i);
                        if (t.path != '/admin') context.push(t.path);
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminSummaryProvider);
                await ref.read(adminSummaryProvider.future);
              },
              child: AsyncScaffoldBody(
                async: async,
                onRetry: () => ref.invalidate(adminSummaryProvider),
                builder: (summary) {
                  if (summary.counts.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: NyumbaTokens.borderRadiusLg,
                          ),
                          child: const Center(
                            child: Text('No scam reports. Platform is fully clear!'),
                          ),
                        ),
                      ],
                    );
                  }

                  final entries = summary.counts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      Text(
                        'Activity overview',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live admin metrics · tap a queue below',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 520;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (var i = 0; i < entries.length; i++)
                                SizedBox(
                                  width: wide
                                      ? (constraints.maxWidth - 10) / 2
                                      : constraints.maxWidth,
                                  child: ScrollReveal(
                                    delay: Duration(milliseconds: 35 * i),
                                    child: PortalMetricCard(
                                      label: _label(entries[i].key),
                                      value: '${entries[i].value}',
                                      subtitle: _subtitleFor(entries[i].key),
                                      icon: _iconFor(entries[i].key),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Queues',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in _tabs.where((e) => e.path != '/admin'))
                            ActionChip(
                              avatar: Icon(_iconForPath(t.path), size: 16),
                              label: Text(
                                t.countKey == null
                                    ? t.label
                                    : '${t.label} (${summary.of(t.countKey!)})',
                              ),
                              onPressed: () => context.push(t.path),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _label(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _subtitleFor(String key) {
    final k = key.toLowerCase();
    if (k.contains('scam')) return 'Needs review';
    if (k.contains('listing')) return 'Moderation queue';
    if (k.contains('provider')) return 'Service intake';
    if (k.contains('portal') || k.contains('application')) return 'Access requests';
    if (k.contains('audit')) return 'Security trail';
    if (k.contains('verif')) return 'Identity / listing checks';
    return 'Live admin metric';
  }

  static IconData _iconFor(String key) {
    final k = key.toLowerCase();
    if (k.contains('scam')) return Icons.report_gmailerrorred_outlined;
    if (k.contains('listing')) return Icons.home_work_outlined;
    if (k.contains('provider')) return Icons.handyman_outlined;
    if (k.contains('portal') || k.contains('application')) {
      return Icons.how_to_reg_outlined;
    }
    if (k.contains('audit')) return Icons.history_edu_outlined;
    if (k.contains('verif')) return Icons.verified_user_outlined;
    if (k.contains('user') || k.contains('member')) return Icons.people_outline;
    return Icons.analytics_outlined;
  }

  static IconData _iconForPath(String path) {
    return switch (path) {
      '/admin/verifications' => Icons.verified_outlined,
      '/admin/identity-verifications' => Icons.badge_outlined,
      '/admin/scams' => Icons.report_outlined,
      '/admin/listings' => Icons.list_alt_outlined,
      '/admin/applications' => Icons.inbox_outlined,
      '/admin/providers' => Icons.handyman_outlined,
      '/admin/pm' => Icons.apartment_outlined,
      '/admin/revenue' => Icons.payments_outlined,
      '/admin/announcements' => Icons.campaign_outlined,
      '/admin/promo' => Icons.local_offer_outlined,
      '/admin/advertise' => Icons.ad_units_outlined,
      _ => Icons.chevron_right,
    };
  }
}

class AdminShimmerGrid extends StatelessWidget {
  const AdminShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1F2937),
      highlightColor: const Color(0xFF374151),
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: List.generate(
          8,
          (_) => Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
