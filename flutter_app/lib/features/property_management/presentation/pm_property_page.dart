import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/property_management/presentation/pm_dense_table.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/empty_state.dart';

List<Map<String, dynamic>> _asMapList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

class PmPropertyDetail {
  const PmPropertyDetail({
    required this.id,
    required this.name,
    this.address,
    this.neighborhood,
    this.status,
    this.units = const [],
    this.tenants = const [],
    this.maintenance = const [],
  });

  final String id;
  final String name;
  final String? address;
  final String? neighborhood;
  final String? status;
  final List<Map<String, dynamic>> units;
  final List<Map<String, dynamic>> tenants;
  final List<Map<String, dynamic>> maintenance;
}

final pmPropertyDetailProvider =
    FutureProvider.autoDispose.family<PmPropertyDetail, String>((ref, id) async {
  final api = ref.watch(mobileApiRepositoryProvider);

  final overviewJson = await api.pmProperty(id);
  final propertyRaw = overviewJson['property'] ?? overviewJson['data'] ?? overviewJson;
  final property = propertyRaw is Map
      ? Map<String, dynamic>.from(propertyRaw)
      : <String, dynamic>{};

  List<Map<String, dynamic>> units = _asMapList(
    overviewJson['units'] ?? property['units'],
  );
  List<Map<String, dynamic>> tenants = _asMapList(
    overviewJson['tenants'] ?? property['tenants'],
  );
  List<Map<String, dynamic>> maintenance = _asMapList(
    overviewJson['maintenance'] ??
        overviewJson['maintenance_requests'] ??
        property['maintenance'],
  );

  // Prefer dedicated section endpoints when overview omits nested lists.
  if (units.isEmpty) {
    try {
      final u = await api.pmUnits(id);
      units = _asMapList(u['units'] ?? u['items'] ?? u['data']);
    } catch (_) {}
  }
  if (tenants.isEmpty) {
    try {
      final t = await api.pmTenants(id);
      tenants = _asMapList(t['tenants'] ?? t['items'] ?? t['data']);
    } catch (_) {}
  }
  if (maintenance.isEmpty) {
    try {
      final m = await api.pmMaintenance(id);
      maintenance = _asMapList(
        m['maintenance'] ??
            m['requests'] ??
            m['items'] ??
            m['data'] ??
            m['maintenance_requests'],
      );
    } catch (_) {}
  }

  return PmPropertyDetail(
    id: property['id']?.toString() ?? id,
    name: (property['name'] as String?) ??
        (property['title'] as String?) ??
        'Managed property',
    address: (property['address'] as String?) ??
        (overviewJson['address'] as String?),
    neighborhood: (property['neighborhood'] as String?) ??
        (overviewJson['neighborhood'] as String?),
    status: property['status'] as String?,
    units: units,
    tenants: tenants,
    maintenance: maintenance,
  );
});

class PmPropertyPage extends ConsumerWidget {
  const PmPropertyPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to view property management',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    context.push(loginLocation(from: '/pm/$propertyId')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(pmPropertyDetailProvider(propertyId));

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: async.when(
            data: (d) => Text(d.name, overflow: TextOverflow.ellipsis),
            loading: () => const Text('Property'),
            error: (_, _) => const Text('Property'),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Units'),
              Tab(text: 'Tenants'),
              Tab(text: 'Rent'),
              Tab(text: 'Maintenance'),
              Tab(text: 'Complaints'),
              Tab(text: 'Staff'),
            ],
          ),
        ),
        body: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(pmPropertyDetailProvider(propertyId)),
          builder: (detail) {
            return TabBarView(
              children: [
                _OverviewTab(detail: detail),
                _UnitsTab(propertyId: propertyId, units: detail.units),
                _TenantsTab(
                  propertyId: propertyId,
                  tenants: detail.tenants,
                  units: detail.units,
                ),
                _RentTab(propertyId: propertyId),
                _MaintenanceTab(
                  propertyId: propertyId,
                  items: detail.maintenance,
                ),
                _ComplaintsTab(propertyId: propertyId),
                _StaffTab(propertyId: propertyId),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.detail});

  final PmPropertyDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final place = [
      if (detail.neighborhood != null && detail.neighborhood!.isNotEmpty)
        detail.neighborhood!,
      if (detail.address != null && detail.address!.isNotEmpty) detail.address!,
    ].join(' · ');
    final dashAsync = ref.watch(pmDashboardProvider(detail.id));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          detail.name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (place.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            place,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (detail.status != null && detail.status!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Chip(label: Text(detail.status!)),
        ],
        const SizedBox(height: 20),
        dashAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => Column(
            children: [
              _StatRow(label: 'Units', value: '${detail.units.length}'),
              _StatRow(label: 'Tenants', value: '${detail.tenants.length}'),
              _StatRow(label: 'Maintenance', value: '${detail.maintenance.length}'),
            ],
          ),
          data: (d) {
            final health = d['health'];
            final healthScore = health is Map
                ? (health['score'] as num?)?.toInt() ??
                    (health['healthScore'] as num?)?.toInt()
                : (d['healthScore'] as num?)?.toInt();
            return Column(
              children: [
                _StatRow(label: 'Units', value: '${d['totalUnits'] ?? detail.units.length}'),
                _StatRow(label: 'Occupied', value: '${d['occupiedUnits'] ?? '—'}'),
                _StatRow(label: 'Vacant', value: '${d['vacantUnits'] ?? '—'}'),
                _StatRow(
                  label: 'Occupancy',
                  value: d['occupancyRate'] != null ? '${d['occupancyRate']}%' : '—',
                ),
                _StatRow(
                  label: 'Expected (month)',
                  value: 'KES ${d['expectedIncome'] ?? 0}',
                ),
                _StatRow(
                  label: 'Collected',
                  value: 'KES ${d['collectedThisMonth'] ?? 0}',
                ),
                _StatRow(
                  label: 'Outstanding',
                  value: 'KES ${d['outstandingRent'] ?? 0}',
                ),
                _StatRow(
                  label: 'Open maintenance',
                  value: '${d['openMaintenanceRequests'] ?? detail.maintenance.length}',
                ),
                if (healthScore != null)
                  _StatRow(label: 'Health score', value: '$healthScore'),
              ],
            );
          },
        ),
      ],
    );
  }
}

final pmDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.watch(mobileApiRepositoryProvider).pmPropertyDashboard(id);
});

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _UnitsTab extends ConsumerWidget {
  const _UnitsTab({required this.propertyId, required this.units});

  final String propertyId;
  final List<Map<String, dynamic>> units;

  Future<void> _addUnit(BuildContext context, WidgetRef ref) async {
    final labelCtrl = TextEditingController();
    final rentCtrl = TextEditingController();
    String unitType = 'bedsitter';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Add unit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(labelText: 'Unit label'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rentCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Monthly rent (KES)'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: unitType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'bedsitter', child: Text('Bedsitter')),
                        DropdownMenuItem(value: '1br', child: Text('1 BR')),
                        DropdownMenuItem(value: '2br', child: Text('2 BR')),
                        DropdownMenuItem(value: '3br', child: Text('3 BR')),
                        DropdownMenuItem(value: '4br+', child: Text('4 BR+')),
                        DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => unitType = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
              ],
            );
          },
        );
      },
    );

    if (ok != true || !context.mounted) return;
    final rent = int.tryParse(rentCtrl.text.trim());
    if (labelCtrl.text.trim().isEmpty || rent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label and rent are required.')),
      );
      return;
    }

    try {
      await ref.read(mobileApiRepositoryProvider).createPmUnit(propertyId, {
        'unitLabel': labelCtrl.text.trim(),
        'monthlyRent': rent,
        'unitType': unitType,
      });
      ref.invalidate(pmPropertyDetailProvider(propertyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit created.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Could not create unit.')),
        );
      }
    }
  }

  Future<void> _editUnit(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> unit,
  ) async {
    final id = unit['id']?.toString();
    if (id == null || id.isEmpty) return;
    final labelCtrl = TextEditingController(
      text: (unit['unit_label'] as String?) ?? (unit['unitLabel'] as String?) ?? '',
    );
    final rentCtrl = TextEditingController(
      text: ((unit['monthly_rent'] as num?)?.toInt() ??
              (unit['monthlyRent'] as num?)?.toInt() ??
              0)
          .toString(),
    );
    String status = (unit['status'] as String?) ?? 'vacant';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Edit unit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(labelText: 'Unit label'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rentCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Monthly rent (KES)'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'vacant', child: Text('Vacant')),
                        DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                        DropdownMenuItem(value: 'notice_given', child: Text('Notice given')),
                        DropdownMenuItem(value: 'vacant_soon', child: Text('Vacant soon')),
                        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => status = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !context.mounted) return;
    final rent = int.tryParse(rentCtrl.text.trim());
    if (labelCtrl.text.trim().isEmpty || rent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label and rent are required.')),
      );
      return;
    }
    try {
      await ref.read(mobileApiRepositoryProvider).updatePmUnit(id, {
        'unitLabel': labelCtrl.text.trim(),
        'monthlyRent': rent,
        'status': status,
      });
      ref.invalidate(pmPropertyDetailProvider(propertyId));
      ref.invalidate(pmDashboardProvider(propertyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit updated.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Could not update unit.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _addUnit(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add unit'),
            ),
          ),
        ),
        Expanded(
          child: units.isEmpty
              ? const EmptyState(
                  compact: true,
                  icon: Icons.meeting_room_outlined,
                  title: 'No units yet',
                  subtitle: 'Add units so you can assign tenants and generate rent.',
                )
              : PmDenseDataTable(
                  minWidth: 560,
                  columns: const [
                    DataColumn(label: Text('Unit')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Rent')),
                    DataColumn(label: Text('Beds')),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final u in units)
                      DataRow(
                        cells: [
                          DataCell(
                            Text(
                              (u['unit_label'] as String?) ??
                                  (u['unitLabel'] as String?) ??
                                  (u['name'] as String?) ??
                                  'Unit',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataCell(Text((u['status'] as String?) ?? '—')),
                          DataCell(
                            Text(
                              () {
                                final rent = (u['monthly_rent'] as num?)?.toInt() ??
                                    (u['monthlyRent'] as num?)?.toInt();
                                return rent == null ? '—' : 'KES $rent';
                              }(),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${(u['bedrooms'] as num?)?.toInt() ?? (u['beds'] as num?)?.toInt() ?? '—'}',
                            ),
                          ),
                          DataCell(
                            IconButton(
                              tooltip: 'Edit unit',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _editUnit(context, ref, u),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TenantsTab extends ConsumerWidget {
  const _TenantsTab({required this.propertyId, required this.tenants, required this.units});

  final String propertyId;
  final List<Map<String, dynamic>> tenants;
  final List<Map<String, dynamic>> units;

  Future<void> _addTenant(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add tenant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        );
      },
    );

    if (ok != true || !context.mounted) return;
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone are required.')),
      );
      return;
    }

    try {
      await ref.read(mobileApiRepositoryProvider).createPmTenant(propertyId, {
        'fullName': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      });
      ref.invalidate(pmPropertyDetailProvider(propertyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant added.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Could not add tenant.')),
        );
      }
    }
  }


  Future<void> _createLease(BuildContext context, WidgetRef ref) async {
    if (units.isEmpty || tenants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a unit and tenant first.')),
      );
      return;
    }

    String? unitId = units.first['id']?.toString();
    String? tenantId = tenants.first['id']?.toString();
    final rentCtrl = TextEditingController(
      text: ((units.first['monthly_rent'] as num?)?.toInt() ??
              (units.first['monthlyRent'] as num?)?.toInt() ??
              0)
          .toString(),
    );
    final startCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final endCtrl = TextEditingController(
      text: DateTime.now().add(const Duration(days: 365)).toIso8601String().substring(0, 10),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Create lease'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: unitId,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: [
                        for (final u in units)
                          DropdownMenuItem(
                            value: u['id']?.toString(),
                            child: Text(
                              (u['unit_label'] as String?) ??
                                  (u['unitLabel'] as String?) ??
                                  'Unit',
                            ),
                          ),
                      ],
                      onChanged: (v) => setLocal(() => unitId = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: tenantId,
                      decoration: const InputDecoration(labelText: 'Tenant'),
                      items: [
                        for (final t in tenants)
                          DropdownMenuItem(
                            value: t['id']?.toString(),
                            child: Text(
                              (t['full_name'] as String?) ??
                                  (t['fullName'] as String?) ??
                                  'Tenant',
                            ),
                          ),
                      ],
                      onChanged: (v) => setLocal(() => tenantId = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rentCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Monthly rent (KES)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(labelText: 'Start (YYYY-MM-DD)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(labelText: 'End (YYYY-MM-DD)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
              ],
            );
          },
        );
      },
    );

    if (ok != true || !context.mounted) return;
    final rent = int.tryParse(rentCtrl.text.trim());
    if (unitId == null || tenantId == null || rent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit, tenant, and rent are required.')),
      );
      return;
    }

    try {
      await ref.read(mobileApiRepositoryProvider).createPmLease(propertyId, {
        'unitId': unitId,
        'tenantId': tenantId,
        'monthlyRent': rent,
        'startDate': startCtrl.text.trim(),
        'endDate': endCtrl.text.trim(),
      });
      ref.invalidate(pmPropertyDetailProvider(propertyId));
      ref.invalidate(pmRentInvoicesProvider(propertyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lease created.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Could not create lease.')),
        );
      }
    }
  }

  Future<void> _inviteTenant(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> tenant,
  ) async {
    final id = tenant['id']?.toString();
    if (id == null || id.isEmpty) return;
    final email = (tenant['email'] as String?)?.trim() ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a tenant email before inviting.')),
      );
      return;
    }
    try {
      final json = await ref.read(mobileApiRepositoryProvider).invitePmTenant(
            propertyId: propertyId,
            tenantId: id,
          );
      ref.invalidate(pmPropertyDetailProvider(propertyId));
      final url = json['inviteUrl'] as String?;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              url != null
                  ? 'Invite emailed. Link: $url'
                  : 'Portal invite sent.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Could not invite.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _addTenant(context, ref),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add tenant'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _createLease(context, ref),
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Create lease'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: tenants.isEmpty
              ? const EmptyState(
                  compact: true,
                  icon: Icons.people_outline,
                  title: 'No tenants yet',
                  subtitle: 'Add a tenant or create a lease to get started.',
                )
              : PmDenseDataTable(
                  minWidth: 640,
                  columns: const [
                    DataColumn(label: Text('Tenant')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Portal')),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final t in tenants)
                      DataRow(
                        cells: [
                          DataCell(
                            Text(
                              (t['full_name'] as String?) ??
                                  (t['fullName'] as String?) ??
                                  (t['name'] as String?) ??
                                  'Tenant',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataCell(Text((t['phone'] as String?) ?? '—')),
                          DataCell(
                            Text(
                              (t['email'] as String?)?.isNotEmpty == true
                                  ? (t['email'] as String)
                                  : '—',
                            ),
                          ),
                          DataCell(
                            Text(
                              (t['portal_status'] as String?) ??
                                  (t['portalStatus'] as String?) ??
                                  '—',
                            ),
                          ),
                          DataCell(
                            ((t['email'] as String?)?.isNotEmpty ?? false)
                                ? TextButton(
                                    onPressed: () => _inviteTenant(context, ref, t),
                                    child: const Text('Invite'),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}


final pmRentLedgerProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, propertyId) async {
  return ref.watch(mobileApiRepositoryProvider).pmRentInvoices(propertyId);
});

/// Back-compat alias used by lease-create invalidate sites.
final pmRentInvoicesProvider = pmRentLedgerProvider;

class _RentTab extends ConsumerWidget {
  const _RentTab({required this.propertyId});

  final String propertyId;

  int _int(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toInt();
    }
    return 0;
  }

  String _str(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return '—';
  }

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> inv,
  ) async {
    final id = inv['id']?.toString();
    if (id == null || id.isEmpty) return;

    final due = _int(inv, ['amountDue', 'amount_due']);
    final paid = _int(inv, ['amountPaid', 'amount_paid']);
    final late = _int(inv, ['lateFee', 'late_fee']);
    final remaining = (inv['balanceRemaining'] as num?)?.toInt() ??
        (due + late - paid).clamp(0, 1 << 30);
    final amountCtrl = TextEditingController(
      text: remaining > 0 ? remaining.toString() : due.toString(),
    );
    String method = 'cash';
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Record payment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Amount (KES)'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: method,
                      decoration: const InputDecoration(labelText: 'Method'),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank')),
                        DropdownMenuItem(value: 'manual', child: Text('Manual')),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => method = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Note (optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Record')),
              ],
            );
          },
        );
      },
    );

    if (ok != true || !context.mounted) return;
    final amount = int.tryParse(amountCtrl.text.trim());
    if (amount == null || amount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a positive amount.')),
      );
      return;
    }

    try {
      await ref.read(mobileApiRepositoryProvider).recordPmPayment(propertyId, {
        'invoiceId': id,
        'amount': amount,
        'method': method,
        'note': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      });
      ref.invalidate(pmRentLedgerProvider(propertyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Could not record payment.')),
        );
      }
    }
  }

  Future<void> _editRent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> inv,
  ) async {
    final invoiceId = inv['id']?.toString();
    final leaseId = inv['leaseId']?.toString() ?? inv['lease_id']?.toString();
    if (invoiceId == null) return;

    final amountCtrl = TextEditingController(
      text: _int(inv, ['amountDue', 'amount_due']).toString(),
    );
    var scope = 'invoice';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Edit rent amount'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Amount (KES)'),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'invoice', label: Text('This month')),
                      ButtonSegment(value: 'lease', label: Text('Lease + month')),
                    ],
                    selected: {scope},
                    onSelectionChanged: (s) => setLocal(() => scope = s.first),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
              ],
            );
          },
        );
      },
    );

    if (ok != true || !context.mounted) return;
    final amount = int.tryParse(amountCtrl.text.trim());
    if (amount == null || amount < 0) return;

    try {
      final api = ref.read(mobileApiRepositoryProvider);
      if (scope == 'lease') {
        if (leaseId == null || leaseId.isEmpty) {
          throw const UnexpectedFailure('Missing lease id');
        }
        await api.updatePmLeaseRent(
          leaseId,
          monthlyRent: amount,
          applyToCurrentInvoice: true,
        );
      } else {
        await api.updatePmInvoiceAmountDue(invoiceId, amountDue: amount);
      }
      ref.invalidate(pmRentLedgerProvider(propertyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rent amount updated.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Could not update rent.')),
        );
      }
    }
  }

  Future<void> _showSms(BuildContext context, Map<String, dynamic> inv) async {
    final payments = inv['payments'];
    if (payments is! List) return;
    final sms = payments.whereType<Map>().where((p) {
      return p['method']?.toString() == 'mpesa_sms';
    }).toList();
    if (sms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pasted M-Pesa messages on this invoice.')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pasted payment messages'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final p in sms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SelectableText(
                    '${p['mpesaReceiptNumber'] ?? p['mpesa_receipt_number'] ?? 'SMS'}\n'
                    '${p['note'] ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pmRentLedgerProvider(propertyId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () async {
                try {
                  final json = await ref
                      .read(mobileApiRepositoryProvider)
                      .generatePmRentInvoices(propertyId);
                  ref.invalidate(pmRentLedgerProvider(propertyId));
                  ref.invalidate(pmDashboardProvider(propertyId));
                  if (context.mounted) {
                    final n = json['seeded'];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          n is num
                              ? 'Generated invoices for $n active lease(s).'
                              : 'Invoices generated for this period.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e is AppFailure ? e.message : 'Could not generate invoices.',
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Generate this month'),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pmRentLedgerProvider(propertyId));
              await ref.read(pmRentLedgerProvider(propertyId).future);
            },
            child: AsyncScaffoldBody(
              async: async,
              onRetry: () => ref.invalidate(pmRentLedgerProvider(propertyId)),
              builder: (payload) {
                final items = _asMapList(payload['items'] ?? payload['invoices'] ?? payload['data']);
                final summary = payload['summary'];
                final collectedMonth = summary is Map
                    ? (summary['collectedMonth'] as num?)?.toInt() ?? 0
                    : 0;
                final collectedYear = summary is Map
                    ? (summary['collectedYear'] as num?)?.toInt() ?? 0
                    : 0;
                final outstanding = summary is Map
                    ? (summary['outstanding'] as num?)?.toInt() ?? 0
                    : 0;

                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      Text(
                        'No rent invoices yet. Create a lease or tap Generate this month.',
                      ),
                    ],
                  );
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _RentStatChip(
                            label: 'This month',
                            value: 'KES $collectedMonth',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RentStatChip(
                            label: 'Year to date',
                            value: 'KES $collectedYear',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RentStatChip(
                            label: 'Outstanding',
                            value: 'KES $outstanding',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PmDenseDataTable(
                      minWidth: 720,
                      columns: const [
                        DataColumn(label: Text('Tenant')),
                        DataColumn(label: Text('Period')),
                        DataColumn(label: Text('Due')),
                        DataColumn(label: Text('Paid')),
                        DataColumn(label: Text('Left')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final inv in items)
                          DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _str(inv, ['tenantName', 'tenant_name']),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      _str(inv, ['unitLabel', 'unit_label']),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(_str(inv, ['periodMonth', 'period_month']))),
                              DataCell(
                                Text(
                                  'KES ${_int(inv, ['amountDue', 'amount_due']) + _int(inv, ['lateFee', 'late_fee'])}',
                                ),
                              ),
                              DataCell(
                                Text('KES ${_int(inv, ['amountPaid', 'amount_paid'])}'),
                              ),
                              DataCell(
                                Text(
                                  'KES ${(inv['balanceRemaining'] as num?)?.toInt() ?? (_int(inv, ['amountDue', 'amount_due']) + _int(inv, ['lateFee', 'late_fee']) - _int(inv, ['amountPaid', 'amount_paid'])).clamp(0, 1 << 30)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => _recordPayment(context, ref, inv),
                                      child: const Text('Record'),
                                    ),
                                    TextButton(
                                      onPressed: () => _editRent(context, ref, inv),
                                      child: const Text('Edit'),
                                    ),
                                    IconButton(
                                      tooltip: 'Pasted SMS',
                                      onPressed: () => _showSms(context, inv),
                                      icon: const Icon(Icons.sms_outlined, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RentStatChip extends StatelessWidget {
  const _RentStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MaintenanceTab extends ConsumerWidget {
  const _MaintenanceTab({
    required this.propertyId,
    required this.items,
  });

  final String propertyId;
  final List<Map<String, dynamic>> items;

  String? _nextOwnerStatus(String status) {
    switch (status) {
      case 'reported':
      case 'accepted':
        return 'in_progress';
      case 'in_progress':
        return 'completed';
      default:
        return null;
    }
  }

  String _actionLabel(String next) {
    if (next == 'in_progress') return 'Start';
    if (next == 'completed') return 'Mark completed';
    return 'Update';
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String status,
  ) async {
    try {
      await ref.read(mobileApiRepositoryProvider).updatePmMaintenanceStatus(
            requestId,
            status: status,
          );
      ref.invalidate(pmPropertyDetailProvider(propertyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status → $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is AppFailure ? e.message : 'Could not update status.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
        compact: true,
        icon: Icons.build_outlined,
        title: 'No maintenance requests',
        subtitle: 'Tenant and staff requests will show up in this queue.',
      );
    }
    return PmDenseDataTable(
      minWidth: 640,
      columns: const [
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Updated')),
        DataColumn(label: Text('')),
      ],
      rows: [
        for (final m in items)
          DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 180,
                  child: Text(
                    (m['title'] as String?) ??
                        (m['description'] as String?) ??
                        'Request',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              DataCell(Text((m['status'] as String?) ?? '—')),
              DataCell(Text((m['category'] as String?) ?? '—')),
              DataCell(
                Text(
                  () {
                    final raw = (m['updated_at'] as String?) ??
                        (m['updatedAt'] as String?) ??
                        (m['created_at'] as String?) ??
                        '';
                    if (raw.isEmpty) return '—';
                    final d = DateTime.tryParse(raw);
                    if (d == null) return raw;
                    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  }(),
                ),
              ),
              DataCell(
                () {
                  final id = m['id']?.toString() ?? '';
                  final status = (m['status'] as String?) ?? '';
                  final next = _nextOwnerStatus(status);
                  if (next == null || id.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return TextButton(
                    onPressed: () => _setStatus(context, ref, id, next),
                    child: Text(_actionLabel(next)),
                  );
                }(),
              ),
            ],
          ),
      ],
    );
  }
}

final pmComplaintsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, propertyId) async {
  final json = await ref.watch(mobileApiRepositoryProvider).pmComplaints(propertyId);
  return _asMapList(json['complaints'] ?? json['items'] ?? json['data']);
});

class _ComplaintsTab extends ConsumerWidget {
  const _ComplaintsTab({required this.propertyId});

  final String propertyId;

  Future<void> _reply(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> row,
  ) async {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;
    final replyCtrl = TextEditingController(
      text: (row['landlordReply'] as String?) ?? (row['landlord_reply'] as String?) ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply'),
        content: TextField(
          controller: replyCtrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Reply to tenant'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final reply = replyCtrl.text.trim();
    if (reply.isEmpty) return;
    try {
      await ref.read(mobileApiRepositoryProvider).replyPmComplaint(id, reply: reply);
      ref.invalidate(pmComplaintsProvider(propertyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Could not reply.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pmComplaintsProvider(propertyId));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pmComplaintsProvider(propertyId));
        await ref.read(pmComplaintsProvider(propertyId).future);
      },
      child: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(pmComplaintsProvider(propertyId)),
        builder: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [Text('No complaints yet.')],
            );
          }
          return PmDenseDataTable(
            minWidth: 720,
            columns: const [
              DataColumn(label: Text('Subject')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Unit')),
              DataColumn(label: Text('Tenant')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final c in items)
                DataRow(
                  onSelectChanged: (c['id']?.toString() ?? '').isEmpty
                      ? null
                      : (_) async {
                          try {
                            await ref
                                .read(mobileApiRepositoryProvider)
                                .markPmComplaintSeen(c['id'].toString());
                            ref.invalidate(pmComplaintsProvider(propertyId));
                          } catch (_) {}
                        },
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          (c['subject'] as String?) ?? 'Complaint',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(Text((c['status'] as String?) ?? '—')),
                    DataCell(
                      Text(
                        (c['unitLabel'] as String?) ??
                            (c['unit_label'] as String?) ??
                            '—',
                      ),
                    ),
                    DataCell(
                      Text(
                        (c['tenantName'] as String?) ??
                            (c['tenant_name'] as String?) ??
                            '—',
                      ),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: 'Reply',
                        icon: const Icon(Icons.reply, size: 18),
                        onPressed: () => _reply(context, ref, c),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

final pmStaffProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, propertyId) async {
  final json = await ref.watch(mobileApiRepositoryProvider).pmStaff(propertyId);
  return _asMapList(json['staff'] ?? json['items'] ?? json['data']);
});

class _StaffTab extends ConsumerWidget {
  const _StaffTab({required this.propertyId});

  final String propertyId;

  Future<void> _addStaff(BuildContext context, WidgetRef ref) async {
    final emailCtrl = TextEditingController();
    String role = 'caretaker';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Add staff'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'User email'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'property_manager', child: Text('Property manager')),
                        DropdownMenuItem(value: 'caretaker', child: Text('Caretaker')),
                        DropdownMenuItem(value: 'security', child: Text('Security')),
                        DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
                        DropdownMenuItem(
                          value: 'maintenance_supervisor',
                          child: Text('Maintenance supervisor'),
                        ),
                        DropdownMenuItem(value: 'reception', child: Text('Reception')),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => role = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !context.mounted) return;
    final email = emailCtrl.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email.')),
      );
      return;
    }
    try {
      await ref.read(mobileApiRepositoryProvider).upsertPmStaff(propertyId, {
        'email': email,
        'role': role,
      });
      ref.invalidate(pmStaffProvider(propertyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff saved.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Could not save staff.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pmStaffProvider(propertyId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _addStaff(context, ref),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add staff'),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pmStaffProvider(propertyId));
              await ref.read(pmStaffProvider(propertyId).future);
            },
            child: AsyncScaffoldBody(
              async: async,
              onRetry: () => ref.invalidate(pmStaffProvider(propertyId)),
              builder: (items) {
                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [Text('No staff assigned yet.')],
                  );
                }
                return PmDenseDataTable(
                  minWidth: 560,
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Email')),
                  ],
                  rows: [
                    for (final s in items)
                      DataRow(
                        cells: [
                          DataCell(
                            Text(
                              () {
                                final profile = s['profile'] is Map
                                    ? Map<String, dynamic>.from(
                                        s['profile'] as Map,
                                      )
                                    : null;
                                return (profile?['full_name'] as String?) ??
                                    (profile?['fullName'] as String?) ??
                                    'Staff';
                              }(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataCell(
                            Text(
                              ((s['role'] as String?) ?? '—')
                                  .replaceAll('_', ' '),
                            ),
                          ),
                          DataCell(
                            Text(
                              () {
                                final profile = s['profile'] is Map
                                    ? Map<String, dynamic>.from(
                                        s['profile'] as Map,
                                      )
                                    : null;
                                return (profile?['phone'] as String?) ?? '—';
                              }(),
                            ),
                          ),
                          DataCell(
                            Text(
                              () {
                                final profile = s['profile'] is Map
                                    ? Map<String, dynamic>.from(
                                        s['profile'] as Map,
                                      )
                                    : null;
                                return (profile?['email'] as String?) ??
                                    (s['email'] as String?) ??
                                    '—';
                              }(),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
