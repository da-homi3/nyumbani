import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

class IntegrationsPage extends ConsumerStatefulWidget {
  const IntegrationsPage({super.key});

  @override
  ConsumerState<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends ConsumerState<IntegrationsPage> {
  final _name = TextEditingController();
  String? _freshKey;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final res = await ref.read(mobileApiRepositoryProvider).createIntegrationKey(
            name: _name.text.trim(),
          );
      setState(() {
        _freshKey = res['apiKey'] as String?;
        _name.clear();
      });
      ref.invalidate(integrationKeysProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keysAsync = ref.watch(integrationKeysProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('API & integrations')),
      body: ListView(
        padding: const EdgeInsets.all(NyumbaTokens.space6),
        children: [
          Text(
            'Connect your CRM via REST API keys (prefix nsk_).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Key name'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: const Text('Create API key'),
          ),
          if (_freshKey != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Copy this key now'),
                subtitle: Text(_freshKey!),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _freshKey!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied')),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          keysAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No API keys yet.');
              }
              return Column(
                children: [
                  for (final k in items)
                    ListTile(
                      title: Text('${k['name']}'),
                      subtitle: Text(
                        '${k['key_prefix']}… · ${k['revoked_at'] != null ? 'revoked' : 'active'}',
                      ),
                      trailing: k['revoked_at'] != null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ref
                                    .read(mobileApiRepositoryProvider)
                                    .revokeIntegrationKey('${k['id']}');
                                ref.invalidate(integrationKeysProvider);
                              },
                            ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }
}

final integrationKeysProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(mobileApiRepositoryProvider).listIntegrationKeys();
  final items = res['items'];
  if (items is List) {
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return const [];
});
