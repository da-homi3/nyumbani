import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class PaymentItem {
  const PaymentItem({
    required this.id,
    required this.amountKes,
    required this.status,
    required this.paymentType,
    this.paymentMethod,
    this.createdAt,
    this.receipt,
  });

  final String id;
  final int amountKes;
  final String status;
  final String paymentType;
  final String? paymentMethod;
  final String? createdAt;
  final String? receipt;

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    return PaymentItem(
      id: json['id']?.toString() ?? '',
      amountKes: (json['amountKes'] as num?)?.toInt() ??
          (json['amount_kes'] as num?)?.toInt() ??
          0,
      status: (json['status'] as String?) ?? 'pending',
      paymentType: (json['paymentType'] as String?) ??
          (json['payment_type'] as String?) ??
          'payment',
      paymentMethod: (json['paymentMethod'] as String?) ??
          (json['payment_method'] as String?),
      createdAt: (json['createdAt'] as String?) ?? (json['created_at'] as String?),
      receipt: (json['receipt'] as String?) ?? (json['mpesa_receipt'] as String?),
    );
  }
}

final paymentsListProvider = FutureProvider.autoDispose<List<PaymentItem>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).listPayments();
  final raw = json['items'] ?? json['payments'] ?? json['data'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => PaymentItem.fromJson(Map<String, dynamic>.from(e)))
      .where((p) => p.id.isNotEmpty)
      .toList();
});

class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Billing')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/billing')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(paymentsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paymentsListProvider);
          await ref.read(paymentsListProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(paymentsListProvider),
          builder: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'No payments yet',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text('Unlocks, Plus, verification, and plan charges will appear here.'),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = items[i];
                return ListTile(
                  leading: Icon(
                    p.status == 'completed' ? Icons.check_circle : Icons.pending_outlined,
                    color: p.status == 'completed'
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text('KES ${p.amountKes} · ${p.paymentType.replaceAll('_', ' ')}'),
                  subtitle: Text(
                    [
                      p.status,
                      if (p.paymentMethod != null) p.paymentMethod!,
                      if (p.createdAt != null) p.createdAt!,
                      if (p.receipt != null && p.receipt!.isNotEmpty) 'Receipt ${p.receipt}',
                    ].join(' · '),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
