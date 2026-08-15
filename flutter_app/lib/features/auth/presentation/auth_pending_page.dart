import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/portal/presentation/portal_apply_card.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/brand_logo.dart';
import 'package:nyumbasearch/shared/widgets/nyumba_app_bar.dart';

/// Pending portal applications after privileged signup (landlord/agency/manager).
class AuthPendingPage extends ConsumerWidget {
  const AuthPendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: const NyumbaAppBar(title: 'Application pending'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/auth/pending')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(portalStatusProvider);
    return Scaffold(
      appBar: const NyumbaAppBar(title: 'Application pending'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(portalStatusProvider);
          await ref.read(portalStatusProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const Center(child: BrandLogo(height: 40)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Under review',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'We’re reviewing your portal application',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'You can browse as a tenant meanwhile. We’ll unlock landlord, agency, or manager tools once approved.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Continue browsing'),
            ),
            const SizedBox(height: 24),
            AsyncScaffoldBody(
              async: async,
              onRetry: () => ref.invalidate(portalStatusProvider),
              builder: (apps) {
                final pending = apps.where((a) => a.status == 'pending').toList();
                final others = apps.where((a) => a.status != 'pending').toList();
                if (apps.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('No applications on file yet.'),
                      const SizedBox(height: 16),
                      const PortalApplyCard(),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final a in pending)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.hourglass_top),
                          title: Text(a.requestedRole),
                          subtitle: Text(
                            [
                              a.status,
                              if (a.organizationName != null) a.organizationName!,
                            ].join(' · '),
                          ),
                        ),
                      ),
                    for (final a in others)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(a.requestedRole),
                        subtitle: Text(
                          [
                            a.status,
                            if (a.rejectionReason != null) a.rejectionReason!,
                          ].join(' · '),
                        ),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Continue browsing'),
                    ),
                    TextButton(
                      onPressed: () => context.push('/portals'),
                      child: const Text('Open portals'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
