import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/portal/presentation/portal_dashboard_page.dart'
    show portalRoleNav;
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/portal_scaffold.dart';

final orgTeamProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).listOrgTeam();
  final raw = json['members'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

final orgMembershipProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).orgMembership();
  final raw = json['membership'];
  if (raw is! Map) return null;
  return Map<String, dynamic>.from(raw);
});

class OrgTeamPage extends ConsumerWidget {
  const OrgTeamPage({super.key, this.portalLabel = 'Team', this.portal});

  final String portalLabel;
  /// When set (`agency` / `manager`), wraps in portal drawer chrome.
  final String? portal;

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite teammate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Invite')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final email = emailCtrl.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email.')),
      );
      return;
    }
    try {
      await ref.read(mobileApiRepositoryProvider).inviteOrgTeamMember(
            email: email,
            fullName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
          );
      ref.invalidate(orgTeamProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite sent.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Invite failed')),
        );
      }
    }
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      await ref.read(mobileApiRepositoryProvider).approveOrgTeamMember(userId);
      ref.invalidate(orgTeamProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member approved.')),
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

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      await ref.read(mobileApiRepositoryProvider).revokeOrgTeamMember(userId);
      ref.invalidate(orgTeamProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed.')),
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
      final body = Padding(
        padding: const EdgeInsets.all(24),
        child: FilledButton(
          onPressed: () => context.push(
            loginLocation(from: portal != null ? '/$portal/team' : '/portals'),
          ),
          child: const Text('Sign in'),
        ),
      );
      if (portal != null) {
        return PortalShell(
          portalLabel: portalLabel,
          title: 'Team',
          navItems: portalRoleNav(portal!),
          body: body,
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(portalLabel)),
        body: body,
      );
    }

    final membershipAsync = ref.watch(orgMembershipProvider);
    final teamAsync = ref.watch(orgTeamProvider);
    final isOwner = membershipAsync.valueOrNull?['isOwner'] == true;

    final content = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(orgTeamProvider);
        ref.invalidate(orgMembershipProvider);
        await ref.read(orgTeamProvider.future);
      },
      child: AsyncScaffoldBody(
        async: teamAsync,
        onRetry: () => ref.invalidate(orgTeamProvider),
        builder: (members) {
          if (members.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const Text('No team members yet.'),
                if (isOwner) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _invite(context, ref),
                    child: const Text('Invite teammate'),
                  ),
                ],
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            itemCount: members.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = members[i];
              final userId = m['userId']?.toString() ?? m['user_id']?.toString() ?? '';
              final role = (m['role'] as String?) ?? '';
              final email = (m['email'] as String?) ?? '';
              final profile = m['profile'] is Map
                  ? Map<String, dynamic>.from(m['profile'] as Map)
                  : null;
              final name = (profile?['full_name'] as String?) ??
                  (profile?['fullName'] as String?) ??
                  email;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(name.isEmpty ? 'Member' : name),
                  subtitle: Text(
                    [
                      if (role.isNotEmpty) role,
                      if (email.isNotEmpty) email,
                    ].join(' · '),
                  ),
                  trailing: !isOwner || role == 'owner'
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (v) {
                            if (userId.isEmpty) return;
                            if (v == 'approve') {
                              _approve(context, ref, userId);
                            } else if (v == 'revoke') {
                              _revoke(context, ref, userId);
                            }
                          },
                          itemBuilder: (ctx) => [
                            if (role == 'pending')
                              const PopupMenuItem(
                                value: 'approve',
                                child: Text('Approve'),
                              ),
                            const PopupMenuItem(
                              value: 'revoke',
                              child: Text('Remove'),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );

    if (portal != null) {
      return PortalShell(
        portalLabel: portalLabel,
        title: 'Team',
        navItems: portalRoleNav(portal!),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Invite',
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => _invite(context, ref),
            ),
        ],
        body: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(portalLabel),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Invite',
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => _invite(context, ref),
            ),
        ],
      ),
      body: content,
    );
  }
}
