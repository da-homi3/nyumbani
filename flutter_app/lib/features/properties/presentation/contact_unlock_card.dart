import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/analytics/analytics_client.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/data/unlock_models.dart';
import 'package:nyumbasearch/features/properties/data/unlock_providers.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/payment_waiting_dialog.dart';

bool isKenyanMpesaPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10 && digits.startsWith('07')) return true;
  if (digits.length == 10 && digits.startsWith('01')) return true;
  if (digits.length == 12 && digits.startsWith('2547')) return true;
  if (digits.length == 12 && digits.startsWith('2541')) return true;
  if (digits.length == 9 && (digits.startsWith('7') || digits.startsWith('1'))) {
    return true;
  }
  return false;
}

class ContactUnlockCard extends ConsumerStatefulWidget {
  const ContactUnlockCard({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ContactUnlockCard> createState() => _ContactUnlockCardState();
}

class _ContactUnlockCardState extends ConsumerState<ContactUnlockCard> {
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

  Future<void> _refresh() async {
    ref.invalidate(unlockStateProvider(widget.listingId));
  }

  void _goLogin() {
    if (!mounted) return;
    context.push(loginLocation(from: '/property/${widget.listingId}'));
  }

  Future<void> _refreshUntilUnlocked({int attempts = 4}) async {
    for (var i = 0; i < attempts; i++) {
      ref.invalidate(unlockStateProvider(widget.listingId));
      final state = await ref.read(unlockStateProvider(widget.listingId).future);
      if (state.unlocked) {
        _trackContactUnlock();
        return;
      }
      await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
    }
  }

  void _trackContactUnlock() {
    ref.read(analyticsProvider).track(
      AnalyticsEvents.contactLandlord,
      {'propertyId': widget.listingId},
    );
  }

  Future<void> _unlockFree() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      _goLogin();
      return;
    }

    setState(() {
      _busy = true;
      _localError = null;
    });

    try {
      final result = await ref.read(unlockRepositoryProvider).initiate(
            listingId: widget.listingId,
          );
      if (result.unlocked) {
        await _refreshUntilUnlocked();
        return;
      }
      if (result.error == 'no_contact') {
        setState(() => _localError = result.message ?? 'Phone not available yet.');
        return;
      }
      // Free path not available — user should use STK below.
      setState(() {
        _localError = result.needsPayment
            ? 'Free unlock unavailable. Pay with M-Pesa STK below.'
            : (result.message ?? 'Could not unlock. Try M-Pesa STK.');
      });
    } catch (e) {
      setState(() {
        _localError = e is AppFailure ? e.message : 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payWithStk() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      _goLogin();
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _localError = 'Enter the M-Pesa number that will receive the STK prompt.');
      return;
    }
    if (!isKenyanMpesaPhone(phone)) {
      setState(() => _localError = 'Enter a valid Kenyan M-Pesa number (e.g. 07XX XXX XXX).');
      return;
    }

    setState(() {
      _busy = true;
      _localError = null;
    });

    try {
      final result = await ref.read(unlockRepositoryProvider).initiate(
            listingId: widget.listingId,
            method: 'mpesa',
            phoneNumber: phone,
            idempotencyKey:
                'unlock-stk-${widget.listingId}-${DateTime.now().millisecondsSinceEpoch}',
          );

      if (result.unlocked) {
        await _refreshUntilUnlocked();
        return;
      }

      if (result.paymentId != null) {
        final ok = await _showStkDialog(
          paymentId: result.paymentId!,
          message: result.message ??
              'STK push sent. Enter your M-Pesa PIN on your phone to confirm.',
        );
        if (ok) await _refreshUntilUnlocked();
        return;
      }

      setState(() {
        _localError = result.message ??
            (result.error == 'no_contact'
                ? 'Phone number is not available for this listing yet.'
                : 'Could not start M-Pesa STK. Check the number and try again.');
      });
    } catch (e) {
      setState(() {
        _localError = e is AppFailure ? e.message : 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payWithCard() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      _goLogin();
      return;
    }

    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      setState(() => _localError = 'Enter a valid email for card receipt, or leave blank.');
      return;
    }

    setState(() {
      _busy = true;
      _localError = null;
    });

    try {
      final result = await ref.read(unlockRepositoryProvider).initiate(
            listingId: widget.listingId,
            method: 'card',
            email: email.isEmpty ? null : email,
            idempotencyKey:
                'unlock-card-${widget.listingId}-${DateTime.now().millisecondsSinceEpoch}',
          );

      if (result.unlocked) {
        await _refreshUntilUnlocked();
        return;
      }

      if (result.hasCardRedirect) {
        final uri = Uri.tryParse(result.redirectUrl!);
        if (uri == null) {
          setState(() => _localError = 'Invalid card checkout URL from payment provider.');
          return;
        }
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened) {
          setState(() => _localError = 'Could not open Pesapal checkout.');
          return;
        }
        if (result.paymentId != null) {
          final ok = await _showStkDialog(
            paymentId: result.paymentId!,
            message: result.message ??
                'Complete card payment in the browser, then return here.',
            title: 'Card payment',
          );
          if (ok) await _refreshUntilUnlocked();
        }
        return;
      }

      setState(() {
        _localError = result.message ?? 'Could not start card payment. Try M-Pesa STK.';
      });
    } catch (e) {
      setState(() {
        _localError = e is AppFailure ? e.message : 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _showStkDialog({
    required String paymentId,
    required String message,
    String title = 'M-Pesa STK',
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
        successMessage: 'Payment confirmed. Unlocking contact…',
        pollPayment: (id) => ref.read(unlockRepositoryProvider).pollPayment(id),
      ),
    );
    return completed == true;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final unlockAsync = ref.watch(unlockStateProvider(widget.listingId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: unlockAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) {
            final msg = err is AppFailure ? err.message : 'Could not load contact options.';
            final needsAuth = err is UnauthorizedFailure ||
                (err is AppFailure && err.code == 'UNAUTHORIZED');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Get landlord contact',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(needsAuth || session == null
                    ? 'Sign in to unlock this landlord\'s number.'
                    : msg),
                const SizedBox(height: 12),
                if (needsAuth || session == null)
                  FilledButton(
                    onPressed: _goLogin,
                    child: const Text('Sign in'),
                  )
                else
                  OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            );
          },
          data: (state) {
            if (state.unlocked && state.phones.isNotEmpty) {
              return _RevealedContacts(phones: state.phones, method: state.method);
            }
            if (state.unlocked && state.phones.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact unlocked',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text('No phone number is on file for this listing yet.'),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Get this landlord\'s number',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(_feeHint(state)),
                if (state.monthlyUnlockSpend > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'You\'ve spent KES ${state.monthlyUnlockSpend} on unlocks this month.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (state.canUnlockFree) ...[
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: _busy ? null : _unlockFree,
                    child: Text(
                      state.plusCanCover
                          ? 'Use ${state.creditsRequired} contact credit${state.creditsRequired == 1 ? '' : 's'}'
                          : 'Use free trial unlock',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Or pay with M-Pesa STK',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
                const SizedBox(height: 12),
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
                    helperText: 'Safaricom will send an STK push to this number.',
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
                  const SizedBox(height: 10),
                  Text(_localError!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _busy ? null : _payWithStk,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open),
                  label: Text(
                    state.fee > 0
                        ? 'Pay KES ${state.fee} via M-Pesa STK'
                        : 'Pay via M-Pesa STK',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _payWithCard,
                  icon: const Icon(Icons.credit_card),
                  label: Text(
                    state.fee > 0
                        ? 'Pay KES ${state.fee} by card (Pesapal)'
                        : 'Pay by card (Pesapal)',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _feeHint(UnlockState state) {
    if (state.plusCanCover) {
      return 'Tenant Plus: ${state.plusContactCredits} credit'
          '${state.plusContactCredits == 1 ? '' : 's'} remaining '
          '(${state.creditsRequired} for this listing).';
    }
    if (state.isPlus) {
      return 'You\'ve used your included contact credits. Pay KES ${state.fee} for this listing, or wait until your next Plus period.';
    }
    if (state.trialActive && state.trialUnlocksRemaining > 0) {
      return 'You have ${state.trialUnlocksRemaining} free unlock'
          '${state.trialUnlocksRemaining == 1 ? '' : 's'} left — or pay KES ${state.fee} via M-Pesa or card.';
    }
    return 'Unlock fee: KES ${state.fee}. Pay with M-Pesa STK (Daraja) or card (Pesapal).';
  }
}

class _RevealedContacts extends StatelessWidget {
  const _RevealedContacts({required this.phones, this.method});

  final List<String> phones;
  final String? method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: NyumbaTokens.easeOutExpo,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: child,
          ),
        );
      },
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              'Contact unlocked',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (method != null) ...[
          const SizedBox(height: 4),
          Text(
            'via $method',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 12),
        for (final phone in phones) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone),
            title: Text(phone, style: theme.textTheme.titleMedium),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Call',
                  onPressed: () async {
                    final uri = Uri(scheme: 'tel', path: phone);
                    final ok = await launchUrl(uri);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open the phone dialer.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.call),
                ),
                IconButton(
                  tooltip: 'WhatsApp',
                  onPressed: () async {
                    final digits = phone.replaceAll(RegExp(r'\D'), '');
                    final intl = digits.startsWith('0') ? '254${digits.substring(1)}' : digits;
                    final uri = Uri.parse('https://wa.me/$intl');
                    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open WhatsApp.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat),
                ),
              ],
            ),
          ),
        ],
      ],
      ),
    );
  }
}
