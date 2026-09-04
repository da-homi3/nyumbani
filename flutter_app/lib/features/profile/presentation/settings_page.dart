import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/notifications/presentation/notification_prefs_panel.dart';
import 'package:nyumbasearch/features/portal/presentation/portal_apply_card.dart';
import 'package:nyumbasearch/features/profile/data/me_providers.dart';
import 'package:nyumbasearch/features/subscriptions/data/subscriptions_repository.dart';
import 'package:nyumbasearch/shared/widgets/ambient_backdrop.dart';
import 'package:nyumbasearch/shared/widgets/brand_logo.dart';
import 'package:nyumbasearch/shared/widgets/motion.dart';

/// Website Settings — Profile / Notifications / Security / Portals / Trust.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.initialTab = 'profile'});

  final String initialTab;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  var _saving = false;
  String? _saveError;
  var _seeded = false;

  static const _tabKeys = ['profile', 'notifications', 'security', 'portals', 'trust'];

  @override
  void initState() {
    super.initState();
    final initial = _tabKeys.indexOf(widget.initialTab);
    _tabs = TabController(
      length: _tabKeys.length,
      vsync: this,
      initialIndex: initial < 0 ? 0 : initial,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).updateProfile({
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      ref.invalidate(meProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    } catch (e) {
      setState(() {
        _saveError = e is AppFailure ? e.message : 'Could not save.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);
    final meAsync = ref.watch(meProvider);
    final plusAsync = ref.watch(entitlementsProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to manage settings',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    meAsync.whenData((me) {
      if (!_seeded && me != null) {
        _seeded = true;
        _nameCtrl.text = me.fullName ?? '';
        _phoneCtrl.text = me.phone ?? '';
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackdrop(opacity: 0.28, particleCount: 10)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const BrandLogo(height: 28, markOnly: true),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              session.user.email ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ScrollReveal(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.black,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(icon: Icon(Icons.person_outline, size: 16), text: 'Profile'),
                        Tab(icon: Icon(Icons.notifications_outlined, size: 16), text: 'Notifications'),
                        Tab(icon: Icon(Icons.lock_outline, size: 16), text: 'Security'),
                        Tab(icon: Icon(Icons.dashboard_outlined, size: 16), text: 'Portals'),
                        Tab(icon: Icon(Icons.shield_outlined, size: 16), text: 'Trust'),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ProfileTab(
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      saving: _saving,
                      error: _saveError,
                      onSave: _saveProfile,
                      plusAsync: plusAsync,
                    ),
                    const SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: NotificationPrefsPanel(),
                    ),
                    _SecurityTab(email: session.user.email ?? ''),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'YOUR PORTALS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () => context.push('/portals'),
                            child: const Text('Open portal switcher'),
                          ),
                          const SizedBox(height: 16),
                          const PortalApplyCard(),
                        ],
                      ),
                    ),
                    _TrustTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.saving,
    required this.error,
    required this.onSave,
    required this.plusAsync,
  });

  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final bool saving;
  final String? error;
  final VoidCallback onSave;
  final AsyncValue<UserEntitlements?> plusAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ScrollReveal(
          child: _SettingsCard(
            label: 'PROFILE',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (M-Pesa)'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: saving ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: NyumbaTokens.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save profile'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ScrollReveal(
          delay: const Duration(milliseconds: 80),
          child: _SettingsCard(
            label: 'NYUMBASEARCH PLUS',
            child: plusAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Could not load Plus status.'),
              data: (status) {
                final active = status is UserEntitlements ? status.isPlus : false;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? 'Active until renewal' : 'Not active',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/plus'),
                      child: Text(
                        active ? 'Manage membership →' : 'Upgrade to Plus →',
                        style: const TextStyle(
                          color: NyumbaTokens.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _SecurityTab extends ConsumerStatefulWidget {
  const _SecurityTab({required this.email});
  final String email;

  @override
  ConsumerState<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends ConsumerState<_SecurityTab> {
  final _emailCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  var _busy = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changeEmail() async {
    final next = _emailCtrl.text.trim().toLowerCase();
    final confirm = _confirmCtrl.text.trim().toLowerCase();
    setState(() {
      _error = null;
      _message = null;
    });
    if (!next.contains('@') || next.length < 5) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'Email addresses do not match.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).updateEmail(next);
      if (!mounted) return;
      _emailCtrl.clear();
      _confirmCtrl.clear();
      setState(() {
        _message =
            'Check your inbox — confirm the new email to finish the change.';
      });
      ref.invalidate(meProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not start email change.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = ref.watch(authSessionProvider).valueOrNull?.user.newEmail;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SettingsCard(
          label: 'CHANGE EMAIL',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Current: ${widget.email}'),
              if (pending != null && pending.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Pending confirmation for $pending. Check that inbox to finish.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'New email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Confirm new email',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(_message!),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _changeEmail,
                child: Text(_busy ? 'Sending…' : 'Send confirmation email'),
              ),
              const SizedBox(height: 8),
              Text(
                'You will receive a confirmation link at the new address before login email updates.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          label: 'SECURITY',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Signed in as ${widget.email}'),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => context.push(
                  '/auth/reset?email=${Uri.encodeComponent(widget.email)}',
                ),
                child: const Text('Reset password'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push('/verify'),
                child: const Text('Request identity verification'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SettingsCard(
          label: 'TRUST & REWARDS',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earn trust by leaving honest reviews and reporting scams. Stronger trust unlocks Plus-style perks over time.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _TrustActionTile(
                icon: Icons.rate_review_outlined,
                title: 'Leave reviews',
                subtitle: 'Verified stays build your trust score',
                onTap: () => context.push('/saved'),
              ),
              _TrustActionTile(
                icon: Icons.compare_arrows,
                title: 'Compare homes',
                subtitle: 'Side-by-side shortlist before you unlock',
                onTap: () => context.push('/compare'),
              ),
              _TrustActionTile(
                icon: Icons.card_giftcard_outlined,
                title: 'Invite & earn',
                subtitle: 'Share your referral code with friends',
                onTap: () => context.push('/referrals'),
              ),
              _TrustActionTile(
                icon: Icons.verified_user_outlined,
                title: 'Verify identity',
                subtitle: 'Level up for landlords and Plus benefits',
                onTap: () => context.push('/verify'),
              ),
              _TrustActionTile(
                icon: Icons.workspace_premium_outlined,
                title: 'NyumbaSearch Plus',
                subtitle: 'Free unlocks, early access, scam scores',
                onTap: () => context.push('/plus'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          label: 'ABOUT & LEGAL',
          child: Column(
            children: [
              _TrustActionTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'NyumbaSearch mission and story',
                onTap: () => context.push('/about'),
              ),
              _TrustActionTile(
                icon: Icons.mail_outline,
                title: 'Contact',
                subtitle: 'Reach the NyumbaSearch team',
                onTap: () => context.push('/contact'),
              ),
              _TrustActionTile(
                icon: Icons.campaign_outlined,
                title: 'Advertise',
                subtitle: 'Packages and inquiries',
                onTap: () => context.push('/advertise'),
              ),
              _TrustActionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy',
                subtitle: 'How we handle your data',
                onTap: () => context.push('/privacy'),
              ),
              _TrustActionTile(
                icon: Icons.description_outlined,
                title: 'Terms of service',
                subtitle: 'Rules of using the product',
                onTap: () => context.push('/terms-of-service'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustActionTile extends StatelessWidget {
  const _TrustActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: NyumbaTokens.borderRadius,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: NyumbaTokens.borderRadius),
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: NyumbaTokens.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

