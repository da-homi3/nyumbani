import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/landlord/presentation/my_listings_page.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class ManagedCaretaker {
  const ManagedCaretaker({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.isActive,
    this.propertyIds = const [],
    this.lastLoginAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final bool isActive;
  final List<String> propertyIds;
  final String? lastLoginAt;

  factory ManagedCaretaker.fromJson(Map<String, dynamic> json) {
    final ids = json['propertyIds'] ?? json['property_ids'];
    return ManagedCaretaker(
      id: json['id']?.toString() ?? '',
      fullName: (json['fullName'] as String?) ??
          (json['full_name'] as String?) ??
          'Caretaker',
      phone: (json['phone'] as String?) ?? '',
      isActive: json['isActive'] == true || json['is_active'] == true,
      lastLoginAt: json['lastLoginAt'] as String? ?? json['last_login_at'] as String?,
      propertyIds: ids is List
          ? ids.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }
}

final managedCaretakersProvider =
    FutureProvider.autoDispose<List<ManagedCaretaker>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).listCaretakers();
  final raw = json['caretakers'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => ManagedCaretaker.fromJson(Map<String, dynamic>.from(e)))
      .where((c) => c.id.isNotEmpty)
      .toList();
});

class CaretakersManagePage extends ConsumerStatefulWidget {
  const CaretakersManagePage({super.key});

  @override
  ConsumerState<CaretakersManagePage> createState() =>
      _CaretakersManagePageState();
}

class _CaretakersManagePageState extends ConsumerState<CaretakersManagePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _selected = <String>{};
  var _busy = false;
  String? _error;
  String? _createdPin;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _error = 'Enter caretaker name.');
      return;
    }
    if (_phoneCtrl.text.trim().length < 9) {
      setState(() => _error = 'Enter a valid phone.');
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = 'Select at least one listing.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _createdPin = null;
    });
    try {
      final json = await ref.read(mobileApiRepositoryProvider).createCaretaker(
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            propertyIds: _selected.toList(),
          );
      final pin = json['pin']?.toString();
      setState(() {
        _createdPin = pin;
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _selected.clear();
      });
      ref.invalidate(managedCaretakersProvider);
      if (mounted && pin != null) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Caretaker created'),
            content: Text('Share this PIN once: $pin'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not create caretaker.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _regen(ManagedCaretaker c) async {
    try {
      final json =
          await ref.read(mobileApiRepositoryProvider).regenerateCaretakerPin(c.id);
      final pin = json['pin']?.toString() ?? '';
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('New PIN for ${c.fullName}'),
          content: Text(pin.isEmpty ? 'PIN regenerated.' : 'New PIN: $pin'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AppFailure ? e.message : 'Failed')),
      );
    }
  }

  Future<void> _revoke(ManagedCaretaker c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke caretaker?'),
        content: Text('${c.fullName} will no longer be able to sign in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(mobileApiRepositoryProvider).revokeCaretaker(c.id);
      ref.invalidate(managedCaretakersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AppFailure ? e.message : 'Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);
    final listings = ref.watch(ownerPropertiesProvider);
    final caretakers = ref.watch(managedCaretakersProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caretakers')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/landlord/caretakers')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Caretakers')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Add caretaker',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: '07XX XXX XXX',
            ),
          ),
          const SizedBox(height: 12),
          Text('Assign listings', style: theme.textTheme.titleSmall),
          AsyncScaffoldBody(
            async: listings,
            onRetry: () => ref.invalidate(ownerPropertiesProvider),
            builder: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Create a listing first.'),
                );
              }
              return Column(
                children: items
                    .map(
                      (p) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.title),
                        value: _selected.contains(p.id),
                        onChanged: _busy
                            ? null
                            : (v) => setState(() {
                                  if (v == true) {
                                    _selected.add(p.id);
                                  } else {
                                    _selected.remove(p.id);
                                  }
                                }),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_createdPin != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last PIN created: $_createdPin',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create caretaker'),
          ),
          const SizedBox(height: 28),
          Text(
            'Your caretakers',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          AsyncScaffoldBody(
            async: caretakers,
            onRetry: () => ref.invalidate(managedCaretakersProvider),
            builder: (items) {
              if (items.isEmpty) {
                return const Text('No caretakers yet.');
              }
              return Column(
                children: items.map((c) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.fullName),
                    subtitle: Text(
                      '${c.phone} · ${c.propertyIds.length} listings'
                      '${c.isActive ? '' : ' · revoked'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'pin') _regen(c);
                        if (v == 'revoke') _revoke(c);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'pin', child: Text('New PIN')),
                        if (c.isActive)
                          const PopupMenuItem(value: 'revoke', child: Text('Revoke')),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
