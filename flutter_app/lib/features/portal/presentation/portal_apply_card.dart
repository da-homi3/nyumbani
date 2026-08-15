import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';

class PortalApplicationItem {
  const PortalApplicationItem({
    required this.id,
    required this.requestedRole,
    required this.status,
    this.organizationName,
    this.rejectionReason,
    this.createdAt,
  });

  final String id;
  final String requestedRole;
  final String status;
  final String? organizationName;
  final String? rejectionReason;
  final String? createdAt;

  factory PortalApplicationItem.fromJson(Map<String, dynamic> json) {
    return PortalApplicationItem(
      id: json['id']?.toString() ?? '',
      requestedRole: (json['requested_role'] as String?) ??
          (json['requestedRole'] as String?) ??
          '',
      status: (json['status'] as String?) ?? 'pending',
      organizationName: (json['organization_name'] as String?) ??
          (json['organizationName'] as String?),
      rejectionReason: (json['rejection_reason'] as String?) ??
          (json['rejectionReason'] as String?),
      createdAt: (json['created_at'] as String?) ?? (json['createdAt'] as String?),
    );
  }
}

final portalStatusProvider =
    FutureProvider.autoDispose<List<PortalApplicationItem>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).portalStatus();
  final raw = json['applications'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => PortalApplicationItem.fromJson(Map<String, dynamic>.from(e)))
      .where((a) => a.id.isNotEmpty)
      .toList();
});

class PortalApplyCard extends ConsumerStatefulWidget {
  const PortalApplyCard({super.key});

  @override
  ConsumerState<PortalApplyCard> createState() => _PortalApplyCardState();
}

class _PortalApplyCardState extends ConsumerState<PortalApplyCard> {
  final _orgCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role = 'landlord';
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _orgCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).portalApply({
        'requestedRole': _role,
        'organizationName': _orgCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      ref.invalidate(portalStatusProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted for review.')),
      );
      _orgCtrl.clear();
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not submit application.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appsAsync = ref.watch(portalStatusProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Apply for a portal',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Landlord, agency, and manager access requires admin approval.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            appsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (apps) {
                if (apps.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    for (final a in apps.take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('${a.requestedRole} · ${a.status}'),
                        subtitle: Text(
                          [
                            if ((a.organizationName ?? '').isNotEmpty) a.organizationName!,
                            if ((a.rejectionReason ?? '').isNotEmpty) a.rejectionReason!,
                          ].join(' · '),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'landlord', child: Text('Landlord')),
                DropdownMenuItem(value: 'agency', child: Text('Agency')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v != null) setState(() => _role = v);
                    },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _orgCtrl,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: _role == 'landlord' ? 'Portfolio / business name' : 'Organization name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneCtrl,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'M-Pesa phone'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit application'),
            ),
          ],
        ),
      ),
    );
  }
}
