import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/property_management/presentation/pm_list_page.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

class PmCreatePage extends ConsumerStatefulWidget {
  const PmCreatePage({super.key});

  @override
  ConsumerState<PmCreatePage> createState() => _PmCreatePageState();
}

class _PmCreatePageState extends ConsumerState<PmCreatePage> {
  static const _types = [
    ('apartment_block', 'Apartment block'),
    ('estate', 'Estate'),
    ('single_unit', 'Single unit'),
    ('commercial', 'Commercial'),
    ('mixed_use', 'Mixed use'),
  ];

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _type = 'apartment_block';
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _neighborhoodCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final json = await ref.read(mobileApiRepositoryProvider).createPmProperty({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'neighborhood': _neighborhoodCtrl.text.trim(),
        'propertyType': _type,
      });
      final property = json['property'] is Map
          ? Map<String, dynamic>.from(json['property'] as Map)
          : json;
      final id = property['id']?.toString();
      ref.invalidate(pmPropertiesProvider);
      if (!mounted) return;
      if (id != null && id.isNotEmpty) {
        context.go('/pm/$id');
      } else {
        context.go('/pm');
      }
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not create property.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add managed property')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/pm/new')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add managed property')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Create a property in the management suite',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Requires an active Property Management subscription.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Property name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: _types
                  .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _type = v ?? _type),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Address is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _neighborhoodCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Neighborhood'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Neighborhood is required'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              if (_error!.toLowerCase().contains('property management') ||
                  _error!.toLowerCase().contains('subscribe') ||
                  _error!.toLowerCase().contains('pm_module')) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/pm/subscribe'),
                  child: const Text('Subscribe to Property Management'),
                ),
              ],
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create property'),
            ),
          ],
        ),
      ),
    );
  }
}
