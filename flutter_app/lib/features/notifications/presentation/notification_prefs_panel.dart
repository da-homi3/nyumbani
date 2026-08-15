import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/features/notifications/data/notifications_repository.dart';

class NotificationPrefsPanel extends ConsumerWidget {
  const NotificationPrefsPanel({super.key});

  Future<void> _toggle(
    WidgetRef ref,
    BuildContext context, {
    required String key,
    required bool value,
  }) async {
    try {
      await ref.read(notificationsRepositoryProvider).updatePrefs({key: value});
      ref.invalidate(notificationPrefsProvider);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is AppFailure ? e.message : 'Could not update preference.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationPrefsProvider);
    final theme = Theme.of(context);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => ListTile(
        title: const Text('Could not load preferences'),
        subtitle: Text(err is AppFailure ? err.message : 'Try again'),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(notificationPrefsProvider),
        ),
      ),
      data: (prefs) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Push notifications'),
              value: prefs.pushEnabled,
              onChanged: (v) => _toggle(ref, context, key: 'push_enabled', value: v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Messages'),
              value: prefs.messages,
              onChanged: (v) => _toggle(ref, context, key: 'messages', value: v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Payments & rent'),
              value: prefs.payments,
              onChanged: (v) => _toggle(ref, context, key: 'payments', value: v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Maintenance'),
              value: prefs.maintenance,
              onChanged: (v) => _toggle(ref, context, key: 'maintenance', value: v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Listing alerts'),
              value: prefs.listings,
              onChanged: (v) => _toggle(ref, context, key: 'listings', value: v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Announcements'),
              value: prefs.announcements,
              onChanged: (v) => _toggle(ref, context, key: 'announcements', value: v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Account'),
              value: prefs.account,
              onChanged: (v) => _toggle(ref, context, key: 'account', value: v),
            ),
          ],
        );
      },
    );
  }
}
