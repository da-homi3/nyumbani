import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/profile/data/me_providers.dart';
import 'package:nyumbasearch/features/portal/presentation/portal_apply_card.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/ambient_backdrop.dart';

class PortalHomePage extends ConsumerStatefulWidget {
  const PortalHomePage({super.key});

  @override
  ConsumerState<PortalHomePage> createState() => _PortalHomePageState();
}

class _PortalHomePageState extends ConsumerState<PortalHomePage> {
  String? _switchingPortal;

  Future<void> _switchAndGo({
    required String portal,
    required String location,
  }) async {
    setState(() => _switchingPortal = portal);
    try {
      await ref.read(mobileApiRepositoryProvider).setActivePortal(portal);
      ref.invalidate(meProvider);
      if (!mounted) return;
      if (location == '/home') {
        context.go(location);
      } else {
        context.push(location);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppFailure ? e.message : 'Could not switch portal.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _switchingPortal = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Portals')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to switch roles',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(loginLocation(from: '/portals')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final meAsync = ref.watch(meProvider);
    final busy = _switchingPortal != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Your portals')),
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientBackdrop(opacity: 0.22, particleCount: 10),
          ),
          meAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) {
              final msg = err is AppFailure ? err.message : 'Could not load roles.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(msg, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(meProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            },
            data: (me) {
              final roles = (me?.roles ?? const <String>[])
                  .map((r) => r.toLowerCase())
                  .toSet();
              final active = me?.activePortal?.toLowerCase();

              final cards = <_PortalCardData>[
                const _PortalCardData(
                  portal: 'tenant',
                  title: 'Tenant',
                  subtitle: 'Browse and save homes',
                  icon: Icons.home_outlined,
                  location: '/home',
                ),
                if (roles.contains('landlord'))
                  const _PortalCardData(
                    portal: 'landlord',
                    title: 'Landlord',
                    subtitle: 'List and manage your homes',
                    icon: Icons.apartment_outlined,
                    location: '/landlord',
                    status: 'ACTIVE',
                  ),
                if (roles.contains('agency'))
                  const _PortalCardData(
                    portal: 'agency',
                    title: 'Real estate agency',
                    subtitle: 'Team listings and agency tools',
                    icon: Icons.business_outlined,
                    location: '/agency',
                    status: 'APPROVED',
                  ),
                if (roles.contains('manager'))
                  const _PortalCardData(
                    portal: 'manager',
                    title: 'Property manager',
                    subtitle: 'Run portfolios and collect rent',
                    icon: Icons.manage_accounts_outlined,
                    location: '/manager',
                  ),
                if (roles.contains('admin'))
                  const _PortalCardData(
                    portal: 'admin',
                    title: 'Admin',
                    subtitle: 'Verifications and applications',
                    icon: Icons.admin_panel_settings_outlined,
                    location: '/admin',
                  ),
                const _PortalCardData(
                  portal: 'services',
                  title: 'Services',
                  subtitle: 'Find service providers',
                  icon: Icons.handyman_outlined,
                  location: '/services',
                  skipActivePortal: true,
                ),
                const _PortalCardData(
                  portal: 'caretaker',
                  title: 'Caretaker',
                  subtitle: 'PIN sign-in from landlord',
                  icon: Icons.vpn_key_outlined,
                  location: '/caretaker/login',
                  skipActivePortal: true,
                ),
              ];

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    'YOUR PORTALS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final card in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: busy
                              ? null
                              : () async {
                                  if (card.skipActivePortal) {
                                    context.push(card.location);
                                    return;
                                  }
                                  await _switchAndGo(
                                    portal: card.portal,
                                    location: card.location,
                                  );
                                },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: active == card.portal
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline
                                        .withValues(alpha: 0.25),
                                width: active == card.portal ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(card.icon, color: theme.colorScheme.primary),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.title,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        card.subtitle,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_switchingPortal == card.portal)
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else if (card.status != null || active == card.portal)
                                  Text(
                                    card.status ?? 'ACTIVE',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const PortalApplyCard(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PortalCardData {
  const _PortalCardData({
    required this.portal,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.location,
    this.skipActivePortal = false,
    this.status,
  });

  final String portal;
  final String title;
  final String subtitle;
  final IconData icon;
  final String location;
  final bool skipActivePortal;
  final String? status;
}
