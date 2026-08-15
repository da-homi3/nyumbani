import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class TenantInvitePreview {
  const TenantInvitePreview({
    required this.valid,
    this.tenantName,
    this.propertyName,
    this.neighborhood,
    this.portalStatus,
    this.hasExistingAccount = false,
  });

  final bool valid;
  final String? tenantName;
  final String? propertyName;
  final String? neighborhood;
  final String? portalStatus;
  final bool hasExistingAccount;

  factory TenantInvitePreview.fromJson(Map<String, dynamic> json) {
    return TenantInvitePreview(
      valid: json['valid'] == true,
      tenantName: json['tenantName'] as String?,
      propertyName: json['propertyName'] as String?,
      neighborhood: json['neighborhood'] as String?,
      portalStatus: json['portalStatus'] as String?,
      hasExistingAccount: json['hasExistingAccount'] == true,
    );
  }
}

final tenantInvitePreviewProvider =
    FutureProvider.autoDispose.family<TenantInvitePreview, String>((ref, token) async {
  final json = await ref.watch(mobileApiRepositoryProvider).tenantInvitePreview(token);
  return TenantInvitePreview.fromJson(json);
});

class TenantInvitePage extends ConsumerStatefulWidget {
  const TenantInvitePage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<TenantInvitePage> createState() => _TenantInvitePageState();
}

class _TenantInvitePageState extends ConsumerState<TenantInvitePage> {
  var _busy = false;
  String? _localError;

  Future<void> _respond(bool accept) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/tenant/invite/${widget.token}'));
      return;
    }

    setState(() {
      _busy = true;
      _localError = null;
    });

    try {
      final json = await ref.read(mobileApiRepositoryProvider).tenantInviteRespond(
            widget.token,
            accept: accept,
          );
      if (!mounted) return;
      final status = (json['status'] as String?) ?? (accept ? 'accepted' : 'declined');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Invitation accepted. Your rent invoices are ready.'
                : 'Invitation declined.',
          ),
        ),
      );
      if (status == 'accepted') {
        context.go('/rent');
      } else {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _localError = e is AppFailure ? e.message : 'Could not respond to invitation.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tenantInvitePreviewProvider(widget.token));
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tenancy invitation')),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(tenantInvitePreviewProvider(widget.token)),
        builder: (preview) {
          if (!preview.valid) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Invitation unavailable',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('This link expired or was already used.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back home'),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                preview.propertyName ?? 'Property',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if ((preview.neighborhood ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(preview.neighborhood!),
              ],
              const SizedBox(height: 12),
              Text(
                'You were invited as ${preview.tenantName ?? 'a tenant'}. '
                'Accept to unlock rent invoices, maintenance, and complaints for this home.',
              ),
              if (preview.portalStatus != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Current status: ${preview.portalStatus}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Text(_localError!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              if (session == null) ...[
                FilledButton(
                  onPressed: () =>
                      context.push(loginLocation(from: '/tenant/invite/${widget.token}')),
                  child: const Text('Sign in to respond'),
                ),
              ] else ...[
                FilledButton(
                  onPressed: _busy ? null : () => _respond(true),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accept invitation'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _busy ? null : () => _respond(false),
                  child: const Text('Decline'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
