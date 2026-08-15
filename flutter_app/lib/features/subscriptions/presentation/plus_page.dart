import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/presentation/contact_unlock_card.dart'
    show isKenyanMpesaPhone;
import 'package:nyumbasearch/features/subscriptions/data/subscriptions_repository.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';
import 'package:nyumbasearch/shared/widgets/motion.dart';
import 'package:nyumbasearch/shared/widgets/payment_waiting_dialog.dart';
import 'package:nyumbasearch/shared/widgets/nyumba_app_bar.dart';

class PlusPage extends ConsumerStatefulWidget {
  const PlusPage({super.key});

  @override
  ConsumerState<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends ConsumerState<PlusPage> {
  static final _checkoutUri = Uri.parse('${AppConfig.apiBaseUrl}/tenant/checkout');

  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  var _busy = false;
  String? _localError;
  String? _selectedCycle;
  String? _selectedMethod;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _openWebsiteCheckout() async {
    final ok = await launchUrl(_checkoutUri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open checkout. Try again from the website.')),
      );
    }
  }

  Future<void> _pay({
    required PlusCatalog catalog,
    required String billingCycle,
    required String paymentMethod,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/plus'));
      return;
    }

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (paymentMethod == 'mpesa' && !isKenyanMpesaPhone(phone)) {
      setState(() => _localError = 'Enter a valid Kenyan M-Pesa number (e.g. 07XX XXX XXX).');
      return;
    }
    if (paymentMethod == 'card' && email.isNotEmpty && !email.contains('@')) {
      setState(() => _localError = 'Enter a valid email for card receipt, or leave blank.');
      return;
    }

    final amountKes =
        billingCycle == 'quarterly' ? catalog.quarterlyKes : catalog.monthlyKes;

    setState(() {
      _busy = true;
      _localError = null;
      _selectedCycle = billingCycle;
      _selectedMethod = paymentMethod;
    });

    try {
      final key =
          'plus-$paymentMethod-$billingCycle-$amountKes-${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref.read(subscriptionsRepositoryProvider).checkoutPlus(
            amountKes: amountKes,
            billingCycle: billingCycle,
            paymentMethod: paymentMethod,
            phoneNumber: phone,
            email: email.isEmpty ? null : email,
            idempotencyKey: key.length > 64 ? key.substring(0, 64) : key,
          );

      if (result.isCompleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NyumbaSearch Plus is active.')),
          );
        }
        ref.invalidate(plusCatalogProvider);
        ref.invalidate(entitlementsProvider);
        return;
      }

      if (paymentMethod == 'card' && result.hasCardRedirect) {
        final uri = Uri.tryParse(result.redirectUrl!);
        if (uri == null) {
          setState(() => _localError = 'Invalid card checkout URL.');
          return;
        }
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened) {
          setState(() => _localError = 'Could not open Pesapal checkout.');
          return;
        }
      }

      final paymentId = result.paymentId;
      if (paymentId == null || paymentId.isEmpty) {
        setState(() {
          _localError = result.message ??
              (paymentMethod == 'card'
                  ? 'Could not start card payment.'
                  : 'Could not start M-Pesa STK.');
        });
        return;
      }

      final ok = await _showPaymentDialog(
        paymentId: paymentId,
        title: paymentMethod == 'card' ? 'Card payment' : 'M-Pesa STK',
        message: result.message ??
            (paymentMethod == 'card'
                ? 'Complete card payment in the browser, then return here.'
                : 'STK push sent. Enter your M-Pesa PIN on your phone to confirm.'),
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment confirmed. Welcome to Plus.')),
        );
        ref.invalidate(plusCatalogProvider);
        ref.invalidate(entitlementsProvider);
      }
    } catch (e) {
      setState(() {
        _localError =
            e is AppFailure ? e.message : 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _selectedCycle = null;
          _selectedMethod = null;
        });
      }
    }
  }

  Future<bool> _showPaymentDialog({
    required String paymentId,
    required String message,
    required String title,
  }) async {
    if (!mounted) return false;
    final isCard = title.toLowerCase().contains('card');
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentWaitingDialog(
        paymentId: paymentId,
        initialMessage: message,
        title: title,
        timeout: isCard ? PaymentWaitingDialog.cardTimeout : PaymentWaitingDialog.stkTimeout,
        successMessage: 'Payment confirmed. Activating Plus…',
        pollPayment: (id) => ref.read(subscriptionsRepositoryProvider).pollPayment(id),
      ),
    );
    return completed == true;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(plusCatalogProvider);
    final entitlementsAsync = ref.watch(entitlementsProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);
    final isPlus = entitlementsAsync.valueOrNull?.isPlus == true;

    return Scaffold(
      appBar: const NyumbaAppBar(title: 'NyumbaSearch Plus'),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(plusCatalogProvider),
        builder: (catalog) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                catalog.name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Find it faster — monthly contact credits, AI matching, and planning tools.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (isPlus) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    () {
                      final ent = entitlementsAsync.valueOrNull;
                      if (ent?.plusExpiresAt != null) {
                        return 'Plus active until ${ent!.plusExpiresAt}. ${ent.plusContactCredits} contact credits remaining.';
                      }
                      return 'Your Plus membership is active. ${ent?.plusContactCredits ?? 0} contact credits remaining.';
                    }(),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PlanLiftCard(
                child: _PriceTile(
                  label: 'Monthly',
                  priceLabel: 'KES ${catalog.monthlyKes}',
                  subtitle: 'Billed every month',
                ),
              ),
              const SizedBox(height: 12),
              PlanLiftCard(
                highlighted: true,
                child: _PriceTile(
                  label: 'BEST VALUE · 3 months',
                  priceLabel: 'KES ${catalog.quarterlyKes}',
                  subtitle:
                      'Was KES ${catalog.quarterlyRegularKes} · save KES ${catalog.savingsKes} · KES ${catalog.effectiveMonthlyKes}/month',
                  highlighted: true,
                ),
              ),
              if (catalog.features.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Included', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final f in catalog.features)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.check_circle, color: theme.colorScheme.secondary, size: 20),
                    title: Text(f),
                  ),
              ],
              const SizedBox(height: 20),
              if (session == null) ...[
                Text(
                  'Sign in to pay with M-Pesa STK or card in the app.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.push(loginLocation(from: '/plus')),
                  child: const Text('Sign in to subscribe'),
                ),
              ] else if (!isPlus) ...[
                TextField(
                  controller: _phoneCtrl,
                  enabled: !_busy,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa phone',
                    hintText: '07XX XXX XXX',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailCtrl,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional, for card)',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                if (_localError != null) ...[
                  const SizedBox(height: 8),
                  Text(_localError!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _pay(
                            catalog: catalog,
                            billingCycle: 'monthly',
                            paymentMethod: 'mpesa',
                          ),
                  child: _busy && _selectedCycle == 'monthly' && _selectedMethod == 'mpesa'
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('M-Pesa · Monthly KES ${catalog.monthlyKes}'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: _busy
                      ? null
                      : () => _pay(
                            catalog: catalog,
                            billingCycle: 'quarterly',
                            paymentMethod: 'mpesa',
                          ),
                  child: _busy && _selectedCycle == 'quarterly' && _selectedMethod == 'mpesa'
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('M-Pesa · Quarterly KES ${catalog.quarterlyKes}'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _pay(
                            catalog: catalog,
                            billingCycle: 'monthly',
                            paymentMethod: 'card',
                          ),
                  icon: const Icon(Icons.credit_card),
                  label: Text('Card · Monthly KES ${catalog.monthlyKes}'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _pay(
                            catalog: catalog,
                            billingCycle: 'quarterly',
                            paymentMethod: 'card',
                          ),
                  icon: const Icon(Icons.credit_card),
                  label: Text('Card · Quarterly KES ${catalog.quarterlyKes}'),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _busy ? null : _openWebsiteCheckout,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Pay on website instead'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({
    required this.label,
    required this.priceLabel,
    required this.subtitle,
    this.highlighted = false,
  });

  final String label;
  final String priceLabel;
  final String subtitle;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (highlighted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Best value',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Text(
          priceLabel,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
