import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class TenantComplaintItem {
  const TenantComplaintItem({
    required this.id,
    required this.subject,
    required this.body,
    required this.status,
    this.landlordReply,
    this.propertyName,
    this.unitLabel,
    this.createdAt,
  });

  final String id;
  final String subject;
  final String body;
  final String status;
  final String? landlordReply;
  final String? propertyName;
  final String? unitLabel;
  final String? createdAt;

  factory TenantComplaintItem.fromJson(Map<String, dynamic> json) {
    return TenantComplaintItem(
      id: json['id']?.toString() ?? '',
      subject: (json['subject'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      landlordReply:
          (json['landlordReply'] as String?) ?? (json['landlord_reply'] as String?),
      propertyName: (json['propertyName'] as String?) ?? (json['property_name'] as String?),
      unitLabel: (json['unitLabel'] as String?) ?? (json['unit_label'] as String?),
      createdAt: (json['createdAt'] as String?) ?? (json['created_at'] as String?),
    );
  }
}

final tenantComplaintsProvider =
    FutureProvider.autoDispose<List<TenantComplaintItem>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).tenantsComplaints();
  final raw = json['items'] ?? json['data'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => TenantComplaintItem.fromJson(Map<String, dynamic>.from(e)))
      .where((c) => c.id.isNotEmpty)
      .toList();
});

class ComplaintsPage extends ConsumerStatefulWidget {
  const ComplaintsPage({super.key});

  @override
  ConsumerState<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends ConsumerState<ComplaintsPage> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  var _busy = false;
  String? _formError;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_subjectCtrl.text.trim().length < 3 || _bodyCtrl.text.trim().length < 5) {
      setState(() => _formError = 'Add a short subject and more detail.');
      return;
    }
    setState(() {
      _busy = true;
      _formError = null;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).createTenantComplaint({
        'subject': _subjectCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
      });
      _subjectCtrl.clear();
      _bodyCtrl.clear();
      ref.invalidate(tenantComplaintsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted.')),
      );
    } catch (e) {
      setState(() {
        _formError = e is AppFailure ? e.message : 'Could not submit complaint.';
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
        appBar: AppBar(title: const Text('Complaints')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to file a complaint',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(loginLocation(from: '/complaints')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(tenantComplaintsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tenantComplaintsProvider);
          await ref.read(tenantComplaintsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'New complaint',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Details',
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
                  : const Text('Submit complaint'),
            ),
            const SizedBox(height: 28),
            Text(
              'Your complaints',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            AsyncScaffoldBody(
              async: async,
              onRetry: () => ref.invalidate(tenantComplaintsProvider),
              builder: (items) {
                if (items.isEmpty) {
                  return Text(
                    'No complaints yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final c in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${c.subject} · ${c.status}'),
                        subtitle: Text(
                          [
                            if (c.propertyName != null) c.propertyName!,
                            c.body,
                            if (c.landlordReply != null && c.landlordReply!.isNotEmpty)
                              'Reply: ${c.landlordReply}',
                          ].join('\n'),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
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
