import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:nyumbasearch/shared/widgets/motion.dart';

class LandlordPlanPage extends ConsumerStatefulWidget {
  const LandlordPlanPage({super.key});

  @override
  ConsumerState<LandlordPlanPage> createState() => _LandlordPlanPageState();
}

class _LandlordPlanPageState extends ConsumerState<LandlordPlanPage> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  var _busy = false;
  String? _localError;
  var _cycle = 'monthly';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay(LandlordPlanOffer plan, {required String method}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/landlord/plan'));
      return;
    }

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (method == 'mpesa' && !isKenyanMpesaPhone(phone)) {
      setState(() => _localError = 'Enter a valid Kenyan M-Pesa number.');
      return;
    }

    final amount = plan.amountForCycle(_cycle);
    setState(() {
      _busy = true;
      _localError = null;
    });

    try {
      final key =
          'll-$method-${plan.id}-$_cycle-$amount-${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref.read(subscriptionsRepositoryProvider).checkoutLandlordPlan(
            planId: plan.id,
            planName: plan.name,
            amountKes: amount,
            billingCycle: _cycle,
            paymentMethod: method,
            phoneNumber: phone,
            email: email.isEmpty ? null : email,
            idempotencyKey: key.length > 64 ? key.substring(0, 64) : key,
          );

      if (result.isCompleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${plan.name} is active.')),
          );
        }
        ref.invalidate(entitlementsProvider);
        ref.invalidate(revenueCatalogProvider);
        return;
      }

      if (method == 'card' && result.hasCardRedirect) {
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
        setState(() => _localError = result.message ?? 'Payment did not start.');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              method == 'mpesa'
                  ? 'Check your phone for the M-Pesa prompt…'
                  : 'Waiting for card payment…',
            ),
          ),
        );
      }

      final polled =
          await ref.read(subscriptionsRepositoryProvider).waitForPayment(paymentId);
      if (!mounted) return;
      if (polled.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plan.name} is active.')),
        );
        ref.invalidate(entitlementsProvider);
      } else if (polled.isFailed) {
        setState(() => _localError = polled.message);
      } else {
        setState(() => _localError = 'Payment still pending. Check Billing shortly.');
      }
    } catch (e) {
      setState(() {
        _localError = e is AppFailure ? e.message : 'Checkout failed. Try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final entitlements = ref.watch(entitlementsProvider).valueOrNull;
    final async = ref.watch(revenueCatalogProvider);
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Landlord plans')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/landlord/plan')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Landlord plans')),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(revenueCatalogProvider),
        builder: (catalog) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (entitlements != null) ...[
                Text(
                  'Current plan: ${entitlements.landlordPlan}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
              ],
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'monthly', label: Text('Monthly')),
                  ButtonSegment(value: 'quarterly', label: Text('Quarterly (−10%)')),
                ],
                selected: {_cycle},
                onSelectionChanged: _busy
                    ? null
                    : (s) => setState(() => _cycle = s.first),
              ),
              const SizedBox(height: 16),
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
                ),
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
              ...catalog.landlordPlans.map((plan) {
                final amount = plan.amountForCycle(_cycle);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PlanLiftCard(
                    highlighted: plan.highlighted,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          plan.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'KES $amount / ${_cycle == 'quarterly' ? '3 months' : 'month'}',
                          style: theme.textTheme.titleMedium,
                        ),
                        if (plan.desc.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(plan.desc),
                        ],
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _pay(plan, method: 'mpesa'),
                          child: Text('Pay M-Pesa · KES $amount'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _pay(plan, method: 'card'),
                          child: const Text('Pay with card'),
                        ),
                      ],
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
