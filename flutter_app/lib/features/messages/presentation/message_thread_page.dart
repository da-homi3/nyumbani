import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/messages/presentation/messages_page.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class ThreadMessage {
  const ThreadMessage({
    required this.id,
    required this.body,
    required this.senderId,
    this.createdAt,
  });

  final String id;
  final String body;
  final String senderId;
  final String? createdAt;

  factory ThreadMessage.fromJson(Map<String, dynamic> json) {
    return ThreadMessage(
      id: json['id']?.toString() ?? '',
      body: (json['body'] as String?) ?? '',
      senderId: (json['sender_id'] as String?) ??
          (json['senderId'] as String?) ??
          '',
      createdAt: (json['created_at'] as String?) ?? (json['createdAt'] as String?),
    );
  }
}

class MessageThreadData {
  const MessageThreadData({
    required this.id,
    required this.title,
    required this.messages,
  });

  final String id;
  final String title;
  final List<ThreadMessage> messages;
}

final messageThreadProvider =
    FutureProvider.autoDispose.family<MessageThreadData, String>((ref, id) async {
  final json = await ref.watch(mobileApiRepositoryProvider).messageThread(id);
  final thread = json['thread'] is Map
      ? Map<String, dynamic>.from(json['thread'] as Map)
      : (json['inquiry'] is Map
          ? Map<String, dynamic>.from(json['inquiry'] as Map)
          : json);
  final property = thread['properties'] is Map
      ? Map<String, dynamic>.from(thread['properties'] as Map)
      : null;
  final title = (thread['title'] as String?) ??
      (property?['title'] as String?) ??
      (json['title'] as String?) ??
      'Conversation';

  final raw = thread['inquiry_messages'] ??
      thread['messages'] ??
      json['messages'] ??
      json['items'];
  final messages = <ThreadMessage>[];
  if (raw is List) {
    for (final e in raw) {
      if (e is Map) {
        final m = ThreadMessage.fromJson(Map<String, dynamic>.from(e));
        if (m.body.isNotEmpty || m.id.isNotEmpty) messages.add(m);
      }
    }
  }

  return MessageThreadData(
    id: (thread['id']?.toString().isNotEmpty == true)
        ? thread['id'].toString()
        : id,
    title: title,
    messages: messages,
  );
});

class MessageThreadPage extends ConsumerStatefulWidget {
  const MessageThreadPage({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<MessageThreadPage> createState() => _MessageThreadPageState();
}

class _MessageThreadPageState extends ConsumerState<MessageThreadPage> {
  final _bodyCtrl = TextEditingController();
  var _sending = false;
  String? _sendError;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) return;

    setState(() {
      _sending = true;
      _sendError = null;
    });

    try {
      await ref.read(mobileApiRepositoryProvider).sendMessage(
            widget.threadId,
            body: body,
          );
      _bodyCtrl.clear();
      ref.invalidate(messageThreadProvider(widget.threadId));
      ref.invalidate(messagesListProvider);
    } catch (e) {
      setState(() {
        _sendError =
            e is AppFailure ? e.message : 'Could not send. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);
    final myId = session?.user.id;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conversation')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Sign in to view this conversation.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(
                  loginLocation(from: '/messages/${widget.threadId}'),
                ),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(messageThreadProvider(widget.threadId));

    return Scaffold(
      appBar: AppBar(
        title: async.when(
          data: (d) => Text(d.title, overflow: TextOverflow.ellipsis),
          loading: () => const Text('Conversation'),
          error: (_, _) => const Text('Conversation'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncScaffoldBody(
              async: async,
              onRetry: () =>
                  ref.invalidate(messageThreadProvider(widget.threadId)),
              builder: (data) {
                if (data.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hello below.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: data.messages.length,
                  itemBuilder: (context, i) {
                    final m = data.messages[i];
                    final mine = myId != null && m.senderId == myId;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(m.body),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_sendError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                _sendError!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bodyCtrl,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sending ? null : _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
