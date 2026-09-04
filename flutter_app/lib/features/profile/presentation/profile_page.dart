import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/maps/data/map_providers.dart';
import 'package:nyumbasearch/features/profile/data/me_models.dart';
import 'package:nyumbasearch/features/profile/data/me_providers.dart';
import 'package:nyumbasearch/features/profile/data/tenant_profile_providers.dart';
import 'package:nyumbasearch/features/subscriptions/data/subscriptions_repository.dart';
import 'package:nyumbasearch/routing/deep_links.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/shared/widgets/brand_logo.dart';
import 'package:nyumbasearch/shared/widgets/portal_scaffold.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _editProfile(BuildContext context, WidgetRef ref, MeSnapshot? me) async {
    final nameCtrl = TextEditingController(text: me?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: me?.phone ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        var busy = false;
        String? error;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Edit profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    enabled: !busy,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    enabled: !busy,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setLocal(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            await ref.read(mobileApiRepositoryProvider).updateProfile({
                              'full_name': nameCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                            });
                            if (ctx.mounted) Navigator.of(ctx).pop(true);
                          } catch (e) {
                            setLocal(() {
                              busy = false;
                              error = e is AppFailure ? e.message : 'Could not save.';
                            });
                          }
                        },
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
    if (saved == true) {
      ref.invalidate(meProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandLogo(height: 26, markOnly: true),
            SizedBox(width: 10),
            Text('Profile'),
          ],
        ),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Could not load session.')),
        data: (session) {
          if (session == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign in to save homes and unlock contacts',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Sign in'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            );
          }

          final meAsync = ref.watch(meProvider);
          return meAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) {
              final msg = err is AppFailure ? err.message : 'Could not load profile.';
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(session.user.email ?? 'Signed in', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(msg),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(meProvider),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 24),
                  _SignOutButton(ref: ref),
                ],
              );
            },
            data: (me) {
              final name = me?.fullName?.trim().isNotEmpty == true
                  ? me!.fullName!
                  : (session.user.email ?? 'NyumbaSearch user');
              final roles = me?.roles ?? const <String>[];
              final portalRoles = me?.portalRoles ?? const <String>[];

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(me?.email ?? session.user.email ?? '', style: theme.textTheme.bodyMedium),
                  if (me?.phone != null && me!.phone!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(me.phone!),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _editProfile(context, ref, me),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile'),
                  ),
                  const SizedBox(height: 16),
                  const _TenantProfileScoreSection(),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final ent = ref.watch(entitlementsProvider).valueOrNull;
                      if (ent == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            ent.isPlus ? Icons.workspace_premium : Icons.card_giftcard,
                          ),
                          title: Text(ent.isPlus ? 'NyumbaSearch Plus active' : 'Free plan'),
                          subtitle: ent.isPlus
                              ? Text(
                                  ent.plusExpiresAt != null
                                      ? '${ent.plusContactCredits} credits · ends ${ent.plusExpiresAt}'
                                      : '${ent.plusContactCredits} contact credits remaining',
                                )
                              : Text(
                                  ent.trialActive
                                      ? '${ent.trialUnlocksRemaining} trial unlock(s) left'
                                      : 'Upgrade for AI, finance tools, and contact credits',
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/plus'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Roles', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (roles.isEmpty)
                        Chip(label: Text(DeepLinks.labelForRole('tenant')))
                      else
                        ...roles.map(
                          (r) => Chip(label: Text(DeepLinks.labelForRole(r))),
                        ),
                    ],
                  ),
                  if ((me?.trialUnlocksRemaining ?? 0) > 0) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.card_giftcard),
                      title: Text('${me!.trialUnlocksRemaining} free unlock(s) left'),
                      subtitle: me.trialEndsAt != null
                          ? Text('Trial ends ${me.trialEndsAt}')
                          : null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Account', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  PortalNavTile(
                    icon: Icons.favorite_outline,
                    title: 'Saved homes',
                    onTap: () => context.push('/saved'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('My viewings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/viewings'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('My applications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/applications'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.swap_horiz),
                    title: const Text('Switch role / portal'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/portals'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.card_giftcard_outlined),
                    title: const Text('Referrals'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/referrals'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.compare_arrows),
                    title: const Text('Compare homes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/compare'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Search alerts'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/saved-searches'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/notifications'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: const Text('Messages'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/messages'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.home_work_outlined),
                    title: const Text('Rent'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/rent'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.build_outlined),
                    title: const Text('Maintenance'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/maintenance'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.report_outlined),
                    title: const Text('Complaints'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/complaints'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: const Text('NyumbaSearch Plus'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/plus'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apartment_outlined),
                    title: const Text('Landlord dashboard'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/landlord'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Billing'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/billing'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.verified_outlined),
                    title: const Text('Verify a property'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/verify'),
                  ),
                  if (portalRoles.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Web portals', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Landlord, agency, and admin tools stay on the website for now.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final role in portalRoles)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.open_in_browser),
                        title: Text('Open ${DeepLinks.labelForRole(role)} portal'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final uri = DeepLinks.portalUriForRole(
                            role,
                            baseUrl: AppConfig.apiBaseUrl,
                          );
                          if (uri == null) return;
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                  ],
                  const SizedBox(height: 28),
                  _SignOutButton(ref: ref),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TenantProfileScoreSection extends ConsumerWidget {
  const _TenantProfileScoreSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(tenantProfileBundleProvider);
    final theme = Theme.of(context);

    return bundleAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, __) => const SizedBox.shrink(),
      data: (bundle) {
        if (bundle == null) return const SizedBox.shrink();
        final score = bundle['score'];
        if (score is! Map) return const SizedBox.shrink();
        final percent = (score['percent'] as num?)?.toInt();
        if (percent == null) return const SizedBox.shrink();

        final missing = score['missing'];
        final nextSteps = missing is List ? missing.take(2).toList() : const [];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tenant profile',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percent%',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Profile completeness — not a credit score',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (nextSteps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final step in nextSteps)
                    if (step is Map && step['action'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '+${step['points'] ?? ''} ${step['action']}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () async {
        await ref.read(authControllerProvider.notifier).signOut();
        ref.read(savedIdsProvider.notifier).clear();
        ref.invalidate(savedListingsProvider);
        ref.invalidate(meProvider);
        if (context.mounted) context.go('/home');
      },
      child: const Text('Sign out'),
    );
  }
}
