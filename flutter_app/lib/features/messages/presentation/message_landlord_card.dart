import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

/// Plus-gated landlord messaging from a property detail page.
class MessageLandlordCard extends ConsumerStatefulWidget {
  const MessageLandlordCard({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<MessageLandlordCard> createState() => _MessageLandlordCardState();
}

class _MessageLandlordCardState extends ConsumerState<MessageLandlordCard> {
  final _ctrl = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/property/${widget.listingId}'));
      return;
    }

    final text = _ctrl.text.trim();
    if (text.length < 3) {
      setState(() => _error = 'Write a short message (at least 3 characters).');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final json = await ref.read(mobileApiRepositoryProvider).createMessage(
            propertyId: widget.listingId,
            message: text,
          );
      final inquiry = json['inquiry'] is Map
          ? Map<String, dynamic>.from(json['inquiry'] as Map)
          : json;
      final id = inquiry['id']?.toString();
      if (!mounted) return;
      if (id == null || id.isEmpty) {
        setState(() => _error = 'Conversation started but no thread id returned.');
        return;
      }
      context.push('/messages/$id');
    } catch (e) {
      final failure = e is AppFailure ? e : null;
      final code = failure?.code;
      setState(() {
        if (code == 'PLUS_REQUIRED') {
          _error = 'NyumbaSearch Plus is required to message landlords.';
        } else {
          _error = failure?.message ?? 'Could not start conversation. Please try again.';
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Message landlord',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Requires NyumbaSearch Plus. Opens a private conversation about this listing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              enabled: !_busy,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Your message',
                hintText: 'Hi, is this still available?',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              if (_error!.contains('Plus')) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/plus'),
                  child: const Text('View Plus plans'),
                ),
              ],
            ],
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _send,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mail_outline),
              label: const Text('Send message'),
            ),
          ],
        ),
      ),
    );
  }
}
