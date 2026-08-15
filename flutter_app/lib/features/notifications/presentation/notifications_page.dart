import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/navigation/in_app_navigation.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/notifications/data/notifications_repository.dart';
import 'package:nyumbasearch/features/notifications/presentation/notification_prefs_panel.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';
import 'package:nyumbasearch/shared/widgets/nyumba_app_bar.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: const NyumbaAppBar(title: 'Notifications'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to see your inbox',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('Payment receipts, rent reminders, and account alerts appear here.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(loginLocation(from: '/notifications')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: NyumbaAppBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref.read(notificationsRepositoryProvider).markAllRead();
                ref.invalidate(notificationsListProvider);
                ref.invalidate(notificationsUnreadCountProvider);
              } catch (e) {
                if (!context.mounted) return;
                final msg = e is AppFailure ? e.message : 'Could not mark all as read.';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsListProvider);
          ref.invalidate(notificationsUnreadCountProvider);
          await ref.read(notificationsListProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(notificationsListProvider),
          builder: (items) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const NotificationPrefsPanel(),
                const SizedBox(height: 16),
                Text('Inbox', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const EmptyState(
                    compact: true,
                    icon: Icons.notifications_none,
                    title: 'No notifications yet',
                    subtitle:
                        'Payment receipts, rent reminders, and account alerts will appear here.',
                  )
                else
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _NotificationTile(n: items[i]),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.n});

  final AppNotification n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: Icon(
        n.isUnread ? Icons.notifications_active : Icons.notifications_none,
        color: n.isUnread ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        n.title.isEmpty ? 'Update' : n.title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: n.isUnread ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n.body.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(n.body),
          ],
          if (n.createdAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              n.createdAt,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      onTap: () async {
        if (n.isUnread) {
          try {
            await ref.read(notificationsRepositoryProvider).markRead(n.id);
            ref.invalidate(notificationsListProvider);
            ref.invalidate(notificationsUnreadCountProvider);
          } catch (_) {
            // Still allow navigation even if mark-read fails.
          }
        }
        final href = n.href?.trim();
        if (href == null || href.isEmpty || !context.mounted) return;
        final router = GoRouter.of(context);
        await InAppNavigation.openHref(router, href);
      },
    );
  }
}
