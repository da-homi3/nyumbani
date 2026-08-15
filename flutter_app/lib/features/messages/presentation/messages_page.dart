import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';
import 'package:nyumbasearch/shared/widgets/nyumba_app_bar.dart';

class MessageThreadSummary {
  const MessageThreadSummary({
    required this.id,
    required this.title,
    this.subtitle,
    this.updatedAt,
    this.unread = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? updatedAt;
  final bool unread;

  factory MessageThreadSummary.fromJson(Map<String, dynamic> json) {
    final property = json['properties'] is Map
        ? Map<String, dynamic>.from(json['properties'] as Map)
        : (json['property'] is Map
            ? Map<String, dynamic>.from(json['property'] as Map)
            : null);
    final profile = json['profiles'] is Map
        ? Map<String, dynamic>.from(json['profiles'] as Map)
        : (json['counterparty'] is Map
            ? Map<String, dynamic>.from(json['counterparty'] as Map)
            : null);

    final title = (json['title'] as String?) ??
        (property?['title'] as String?) ??
        (profile?['full_name'] as String?) ??
        'Conversation';

    final messages = json['inquiry_messages'] ?? json['messages'];
    String? lastBody;
    if (messages is List && messages.isNotEmpty) {
      final last = messages.last;
      if (last is Map) {
        lastBody = last['body'] as String?;
      }
    }

    return MessageThreadSummary(
      id: json['id']?.toString() ?? '',
      title: title,
      subtitle: lastBody ??
          (json['preview'] as String?) ??
          (json['last_message'] as String?) ??
          (property?['neighborhood'] as String?),
      updatedAt: (json['updated_at'] as String?) ?? (json['updatedAt'] as String?),
      unread: json['unread'] == true || json['has_unread'] == true,
    );
  }
}

final messagesListProvider =
    FutureProvider.autoDispose<List<MessageThreadSummary>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).listMessages();
  final raw = json['messages'] ??
      json['conversations'] ??
      json['items'] ??
      json['data'] ??
      json['inquiries'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => MessageThreadSummary.fromJson(Map<String, dynamic>.from(e)))
      .where((t) => t.id.isNotEmpty)
      .toList();
});

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: const NyumbaAppBar(title: 'Messages'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to view messages',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Conversations with landlords and leads appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(loginLocation(from: '/messages')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(messagesListProvider);

    return Scaffold(
      appBar: const NyumbaAppBar(title: 'Messages'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(messagesListProvider);
          await ref.read(messagesListProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(messagesListProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 24),
                  EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No messages yet',
                    subtitle:
                        'When you unlock a contact or start a conversation, threads show up here.',
                    actionLabel: 'Browse homes',
                    onAction: () => context.go('/search'),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                NyumbaTokens.shellBottomInset(context),
              ),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = items[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      foregroundColor: theme.colorScheme.primary,
                      child: Icon(
                        t.unread ? Icons.mark_chat_unread_outlined : Icons.chat_bubble_outline,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      t.title,
                      style: t.unread
                          ? const TextStyle(fontWeight: FontWeight.w700)
                          : null,
                    ),
                    subtitle: t.subtitle == null || t.subtitle!.isEmpty
                        ? null
                        : Text(
                            t.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/messages/${t.id}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
