import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/presentation/contact_unlock_card.dart'
    show isKenyanMpesaPhone;
import 'package:nyumbasearch/features/subscriptions/data/subscriptions_repository.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class LeadPacksPage extends ConsumerStatefulWidget {
  const LeadPacksPage({super.key});

  @override
  ConsumerState<LeadPacksPage> createState() => _LeadPacksPageState();
}

class _LeadPacksPageState extends ConsumerState<LeadPacksPage> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  var _busy = false;
  String? _localError;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay(LeadPackOffer pack, {required String method}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/landlord/leads'));
      return;
    }

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (method == 'mpesa' && !isKenyanMpesaPhone(phone)) {
      setState(() => _localError = 'Enter a valid Kenyan M-Pesa number.');
      return;
    }

    setState(() {
      _busy = true;
      _localError = null;
    });

    try {
      final key =
          'leads-$method-${pack.qty}-${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref.read(subscriptionsRepositoryProvider).checkoutLeadPack(
            qty: pack.qty,
            amountKes: pack.priceKes,
            label: pack.label,
            paymentMethod: method,
            phoneNumber: phone,
            email: email.isEmpty ? null : email,
            idempotencyKey: key.length > 64 ? key.substring(0, 64) : key,
          );

      if (result.isCompleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pack.label} added to your balance.')),
          );
        }
        ref.invalidate(entitlementsProvider);
        return;
      }

      if (method == 'card' && result.hasCardRedirect) {
        final uri = Uri.tryParse(result.redirectUrl!);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      final paymentId = result.paymentId;
      if (paymentId == null || paymentId.isEmpty) {
        setState(() => _localError = result.message ?? 'Payment did not start.');
        return;
      }

      final polled =
          await ref.read(subscriptionsRepositoryProvider).waitForPayment(paymentId);
      if (!mounted) return;
      if (polled.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pack.label} added to your balance.')),
        );
        ref.invalidate(entitlementsProvider);
      } else {
        setState(() => _localError = polled.message);
      }
    } catch (e) {
      setState(() {
        _localError = e is AppFailure ? e.message : 'Checkout failed.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final entitlements = ref.watch(entitlementsProvider).valueOrNull;
    final catalog = ref.watch(revenueCatalogProvider);
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead packs')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/landlord/leads')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lead packs')),
      body: AsyncScaffoldBody(
        async: catalog,
        onRetry: () => ref.invalidate(revenueCatalogProvider),
        builder: (rev) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (entitlements != null)
                Text(
                  'Lead balance: ${entitlements.leadPackBalance}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'M-Pesa phone'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (card receipt, optional)',
                ),
              ),
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Text(_localError!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              ...rev.leadPacks.map((pack) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            pack.label,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('KES ${pack.priceKes}'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _busy ? null : () => _pay(pack, method: 'mpesa'),
                            child: Text('Pay M-Pesa · KES ${pack.priceKes}'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _busy ? null : () => _pay(pack, method: 'card'),
                            child: const Text('Pay with card'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
