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

class PmSubscribePage extends ConsumerStatefulWidget {
  const PmSubscribePage({super.key});

  @override
  ConsumerState<PmSubscribePage> createState() => _PmSubscribePageState();
}

class _PmSubscribePageState extends ConsumerState<PmSubscribePage> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  var _busy = false;
  String? _message;
  var _success = false;
  int? _priceKes;
  String? _tier;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/pm/subscribe'));
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
      _success = false;
    });

    try {
      final result =
          await ref.read(subscriptionsRepositoryProvider).subscribePmModule();
      if (!mounted) return;

      if (result.alreadyActive || result.trialStarted) {
        setState(() {
          _success = true;
          _message = result.trialStarted
              ? '30-day trial started${result.tier != null ? ' (${result.tier})' : ''}.'
              : 'Property Management is already active.';
          _tier = result.tier;
          _priceKes = result.priceKes;
        });
        return;
      }

      if (result.requiresPayment) {
        setState(() {
          _tier = result.tier;
          _priceKes = result.priceKes;
          _message =
              'Payment required: KES ${result.priceKes ?? '—'} for ${result.tier ?? 'PM'}.';
        });
        return;
      }

      setState(() => _message = 'Unexpected status: ${result.status}');
    } catch (e) {
      setState(() {
        _message = e is AppFailure ? e.message : 'Could not start subscription.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay({required String method}) async {
    final price = _priceKes;
    final tier = _tier;
    if (price == null || tier == null) {
      setState(() => _message = 'Tap Start first to get your recommended price.');
      return;
    }

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (method == 'mpesa' && !isKenyanMpesaPhone(phone)) {
      setState(() => _message = 'Enter a valid Kenyan M-Pesa number.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final key =
          'pm-$method-$tier-$price-${DateTime.now().millisecondsSinceEpoch}';
      final checkout = await ref.read(subscriptionsRepositoryProvider).checkoutPmModule(
            amountKes: price,
            tier: tier,
            paymentMethod: method,
            phoneNumber: phone,
            email: email.isEmpty ? null : email,
            idempotencyKey: key.length > 64 ? key.substring(0, 64) : key,
          );

      if (checkout.isCompleted) {
        setState(() {
          _success = true;
          _message = 'Property Management is active.';
        });
        return;
      }

      if (method == 'card' && checkout.hasCardRedirect) {
        final uri = Uri.tryParse(checkout.redirectUrl!);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      final paymentId = checkout.paymentId;
      if (paymentId == null || paymentId.isEmpty) {
        setState(() => _message = checkout.message ?? 'Payment did not start.');
        return;
      }

      final polled =
          await ref.read(subscriptionsRepositoryProvider).waitForPayment(paymentId);
      if (!mounted) return;
      if (polled.isCompleted) {
        setState(() {
          _success = true;
          _message = 'Property Management is active.';
        });
      } else {
        setState(() => _message = polled.message);
      }
    } catch (e) {
      setState(() {
        _message = e is AppFailure ? e.message : 'Payment failed.';
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
        appBar: AppBar(title: const Text('PM subscribe')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/pm/subscribe')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Property Management')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Subscribe to manage rent, tenants, and maintenance',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'First-time subscribers get a 30-day trial. Returning accounts pay the recommended tier.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _start,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start / check eligibility'),
          ),
          if (_priceKes != null) ...[
            const SizedBox(height: 20),
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
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : () => _pay(method: 'mpesa'),
              child: Text('Pay M-Pesa · KES $_priceKes'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => _pay(method: 'card'),
              child: const Text('Pay with card'),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: TextStyle(
                color: _success
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
          if (_success) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.go('/pm'),
              child: const Text('Go to managed properties'),
            ),
          ],
        ],
      ),
    );
  }
}
