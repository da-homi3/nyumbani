import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

final providerCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).providerCategories();
  final raw = json['categories'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class ProviderRegisterPage extends ConsumerStatefulWidget {
  const ProviderRegisterPage({super.key});

  @override
  ConsumerState<ProviderRegisterPage> createState() => _ProviderRegisterPageState();
}

class _ProviderRegisterPageState extends ConsumerState<ProviderRegisterPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areasCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final Set<String> _categories = {};
  var _busy = false;
  String? _message;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areasCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final areas = _areasCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (_nameCtrl.text.trim().length < 2 ||
        _phoneCtrl.text.trim().length < 9 ||
        _categories.isEmpty ||
        areas.isEmpty) {
      setState(() => _message = 'Name, phone, category, and areas are required.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final api = ref.read(mobileApiRepositoryProvider);
      final body = <String, dynamic>{
        'businessName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'categories': _categories.toList(),
        'areasServed': areas,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'priceRange': _priceCtrl.text.trim().isEmpty ? null : _priceCtrl.text.trim(),
      };
      final existing = await api.providerMe();
      final hasProfile = existing['provider'] is Map;
      final res = hasProfile
          ? await api.patchProviderMe(body)
          : await api.registerProvider(body);
      if (!mounted) return;
      final status = (res['provider'] is Map
              ? (res['provider'] as Map)['status']
              : null)
          ?.toString() ??
          res['status']?.toString() ??
          'pending';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasProfile ? 'Profile updated ($status).' : 'Submitted ($status).'),
        ),
      );
      context.go('/services/me');
    } catch (e) {
      setState(() {
        _message = e is AppFailure ? e.message : 'Could not register.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);
    final catsAsync = ref.watch(providerCategoriesProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Register as provider')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () =>
                context.push(loginLocation(from: '/services/register')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Register as provider')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Offer your services on NyumbaSearch',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Business name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _areasCtrl,
            decoration: const InputDecoration(
              labelText: 'Areas served (comma-separated)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            decoration: const InputDecoration(labelText: 'Price range (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
          ),
          const SizedBox(height: 16),
          Text('Categories', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          catsAsync.when(
            data: (cats) {
              if (cats.isEmpty) {
                return const Text('Categories unavailable.');
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cats)
                    FilterChip(
                      label: Text(
                        (c['label'] as String?) ?? (c['id'] as String?) ?? '',
                      ),
                      selected: _categories.contains(c['id']?.toString()),
                      onSelected: (sel) {
                        final id = c['id']?.toString();
                        if (id == null) return;
                        setState(() {
                          if (sel) {
                            _categories.add(id);
                          } else {
                            _categories.remove(id);
                          }
                        });
                      },
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(e.toString()),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}
