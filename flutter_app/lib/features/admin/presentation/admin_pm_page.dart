import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final adminPmOverviewProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(mobileApiRepositoryProvider).adminPmOverview();
});

class AdminPmPage extends ConsumerWidget {
  const AdminPmPage({super.key});

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    String disputeId,
    String outcome,
  ) async {
    final notesCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(outcome == 'uphold_tenant' ? 'Uphold tenant' : 'Uphold landlord'),
        content: TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resolve')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final notes = notesCtrl.text.trim();
    if (notes.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add notes (min 3 characters).')),
      );
      return;
    }
    try {
      await ref.read(mobileApiRepositoryProvider).resolveAdminPmDispute(
            disputeId,
            outcome: outcome,
            notes: notes,
          );
      ref.invalidate(adminPmOverviewProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute resolved.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : 'Failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PM oversight')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/admin/pm')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(adminPmOverviewProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('PM oversight')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminPmOverviewProvider);
          await ref.read(adminPmOverviewProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(adminPmOverviewProvider),
          builder: (json) {
            final subs = (json['activePmSubscriptions'] is List)
                ? (json['activePmSubscriptions'] as List)
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : <Map<String, dynamic>>[];
            final disputes = (json['openDisputes'] is List)
                ? (json['openDisputes'] as List)
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : <Map<String, dynamic>>[];
            final reversals = (json['recentReversals'] is List)
                ? (json['recentReversals'] as List)
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : <Map<String, dynamic>>[];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  'Open disputes (${disputes.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (disputes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('None open.'),
                  )
                else
                  ...disputes.map((d) {
                    final id = d['id']?.toString() ?? '';
                    final reason = (d['reason'] as String?) ?? '';
                    final claim = d['claim'] is Map
                        ? Map<String, dynamic>.from(d['claim'] as Map)
                        : null;
                    final amount = (claim?['amountClaimed'] as num?)?.toInt();
                    return Card(
                      child: ListTile(
                        title: Text(reason.isEmpty ? 'Dispute' : reason),
                        subtitle: Text(
                          [
                            if (amount != null) 'KES $amount',
                            if (claim?['method'] != null) '${claim!['method']}',
                          ].join(' · '),
                        ),
                        trailing: id.isEmpty
                            ? null
                            : PopupMenuButton<String>(
                                onSelected: (v) =>
                                    _resolve(context, ref, id, v),
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(
                                    value: 'uphold_tenant',
                                    child: Text('Uphold tenant'),
                                  ),
                                  PopupMenuItem(
                                    value: 'uphold_landlord',
                                    child: Text('Uphold landlord'),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                Text(
                  'PM subscriptions (${subs.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                ...subs.take(20).map((s) {
                  final name = (s['fullName'] as String?) ?? 'User';
                  final plan = (s['plan'] as String?) ?? '';
                  final status = (s['status'] as String?) ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        [plan, status].where((e) => e.isNotEmpty).join(' · '),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text(
                  'Recent reversals (${reversals.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (reversals.isEmpty)
                  const Text('None.')
                else
                  ...reversals.take(15).map((r) {
                    final amount = (r['amount'] as num?)?.toInt();
                    final reason = (r['reversalReason'] as String?) ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8, top: 4),
                      child: ListTile(
                        title: Text(amount == null ? 'Reversal' : 'KES $amount'),
                        subtitle: reason.isEmpty ? null : Text(reason),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
