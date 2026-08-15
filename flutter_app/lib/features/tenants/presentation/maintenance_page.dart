import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

const _categories = <({String id, String label})>[
  (id: 'plumbing', label: 'Plumbing'),
  (id: 'electrical', label: 'Electrical'),
  (id: 'security', label: 'Security'),
  (id: 'internet', label: 'Internet'),
  (id: 'cleaning', label: 'Cleaning'),
  (id: 'water', label: 'Water'),
  (id: 'structural', label: 'Structural'),
  (id: 'other', label: 'Other'),
];

const _priorities = <({String id, String label})>[
  (id: 'low', label: 'Low'),
  (id: 'normal', label: 'Normal'),
  (id: 'high', label: 'High'),
  (id: 'urgent', label: 'Urgent'),
];

class TenantMaintenanceItem {
  const TenantMaintenanceItem({
    required this.id,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    this.propertyName,
    this.unitLabel,
    this.createdAt,
  });

  final String id;
  final String category;
  final String description;
  final String priority;
  final String status;
  final String? propertyName;
  final String? unitLabel;
  final String? createdAt;

  factory TenantMaintenanceItem.fromJson(Map<String, dynamic> json) {
    return TenantMaintenanceItem(
      id: json['id']?.toString() ?? '',
      category: (json['category'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      priority: (json['priority'] as String?) ?? 'normal',
      status: (json['status'] as String?) ?? '',
      propertyName: (json['propertyName'] as String?) ?? (json['property_name'] as String?),
      unitLabel: (json['unitLabel'] as String?) ?? (json['unit_label'] as String?),
      createdAt: (json['createdAt'] as String?) ?? (json['created_at'] as String?),
    );
  }
}

final tenantMaintenanceProvider =
    FutureProvider.autoDispose<List<TenantMaintenanceItem>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).tenantsMaintenance();
  final raw = json['items'] ?? json['data'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => TenantMaintenanceItem.fromJson(Map<String, dynamic>.from(e)))
      .where((m) => m.id.isNotEmpty)
      .toList();
});

class MaintenancePage extends ConsumerStatefulWidget {
  const MaintenancePage({super.key});

  @override
  ConsumerState<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends ConsumerState<MaintenancePage> {
  final _descCtrl = TextEditingController();
  String _category = 'plumbing';
  String _priority = 'normal';
  var _busy = false;
  String? _formError;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_descCtrl.text.trim().length < 5) {
      setState(() => _formError = 'Describe the issue (at least 5 characters).');
      return;
    }
    setState(() {
      _busy = true;
      _formError = null;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).createTenantMaintenance({
        'category': _category,
        'priority': _priority,
        'description': _descCtrl.text.trim(),
      });
      _descCtrl.clear();
      ref.invalidate(tenantMaintenanceProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance request submitted.')),
      );
    } catch (e) {
      setState(() {
        _formError = e is AppFailure ? e.message : 'Could not submit request.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(String requestId, {required bool resolved}) async {
    setState(() => _busy = true);
    try {
      await ref.read(mobileApiRepositoryProvider).confirmTenantMaintenance(
            requestId,
            resolved: resolved,
          );
      ref.invalidate(tenantMaintenanceProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resolved ? 'Marked resolved.' : 'Reopened with owner.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is AppFailure ? e.message : 'Could not update request.'),
        ),
      );
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
        appBar: AppBar(title: const Text('Maintenance')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to report maintenance',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(loginLocation(from: '/maintenance')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(tenantMaintenanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tenantMaintenanceProvider);
          await ref.read(tenantMaintenanceProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'New request',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c.id, child: Text(c.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in _priorities)
                  DropdownMenuItem(value: p.id, child: Text(p.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _priority = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                border: OutlineInputBorder(),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(_formError!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit request'),
            ),
            const SizedBox(height: 28),
            Text(
              'Your requests',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            AsyncScaffoldBody(
              async: async,
              onRetry: () => ref.invalidate(tenantMaintenanceProvider),
              builder: (items) {
                if (items.isEmpty) {
                  return Text(
                    'No maintenance requests yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final m in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${m.category} · ${m.status}'),
                        subtitle: Text(
                          [
                            if (m.propertyName != null) m.propertyName!,
                            if (m.unitLabel != null) m.unitLabel!,
                            m.description,
                          ].join(' · '),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: m.status == 'completed',
                        trailing: m.status == 'completed'
                            ? Wrap(
                                spacing: 4,
                                children: [
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _confirm(m.id, resolved: true),
                                    child: const Text('Confirm'),
                                  ),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _confirm(m.id, resolved: false),
                                    child: const Text('Reopen'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
