import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final adminPromoProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(mobileApiRepositoryProvider).adminPromo();
});

class AdminPromoPage extends ConsumerWidget {
  const AdminPromoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPromoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Founding promo')),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(adminPromoProvider),
        builder: (data) {
          final campaigns = (data['campaigns'] as List?) ?? const [];
          final pending = (data['pendingConversions'] as List?) ?? const [];
          final forfeited = data['forfeitedCount'] ?? 0;
          return ListView(
            padding: const EdgeInsets.all(NyumbaTokens.space6),
            children: [
              Text('Campaign slots', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (campaigns.isEmpty)
                const Text('No promo campaigns configured.')
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Claimed')),
                      DataColumn(label: Text('Confirmed')),
                      DataColumn(label: Text('Remaining')),
                      DataColumn(label: Text('Bonus')),
                    ],
                    rows: [
                      for (final raw in campaigns)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                ((raw as Map)['role'] as String? ?? '—')
                                    .replaceAll('_', ' '),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${raw['slots_claimed'] ?? 0} / ${raw['max_slots'] ?? 0}',
                              ),
                            ),
                            DataCell(Text('${raw['slots_confirmed'] ?? 0}')),
                            DataCell(
                              Text(
                                '${(((raw['max_slots'] as num?)?.toInt() ?? 0) - ((raw['slots_claimed'] as num?)?.toInt() ?? 0)).clamp(0, 1 << 30)}',
                              ),
                            ),
                            DataCell(Text('+${raw['bonus_listings'] ?? 0}')),
                          ],
                        ),
                    ],
                  ),
                ),
              if (forfeited is num && forfeited > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$forfeited forfeited slot(s) — released back to the pool.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Pending conversions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (pending.isEmpty)
                const Text('No pending founding members.')
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Slot')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Claimed')),
                    ],
                    rows: [
                      for (final raw in pending)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '#${(raw as Map)['founding_member_slot_number'] ?? '—'}',
                              ),
                            ),
                            DataCell(Text('${raw['full_name'] ?? '—'}')),
                            DataCell(Text('${raw['email'] ?? '—'}')),
                            DataCell(
                              Text(
                                () {
                                  final rawAt =
                                      raw['founding_member_claimed_at'] as String?;
                                  if (rawAt == null) return '—';
                                  final d = DateTime.tryParse(rawAt);
                                  if (d == null) return rawAt;
                                  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                                }(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
