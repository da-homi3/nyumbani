import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/presentation/contact_unlock_card.dart'
    show isKenyanMpesaPhone;
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class PayoutDestination {
  const PayoutDestination({
    required this.id,
    required this.destinationType,
    this.mpesaPhone,
    this.mpesaTill,
    this.mpesaPaybill,
    this.bankName,
    this.bankAccountNumber,
    this.verified = false,
    this.isActive = true,
  });

  final String id;
  final String destinationType;
  final String? mpesaPhone;
  final String? mpesaTill;
  final String? mpesaPaybill;
  final String? bankName;
  final String? bankAccountNumber;
  final bool verified;
  final bool isActive;

  String get summary {
    switch (destinationType) {
      case 'mpesa_phone':
        return mpesaPhone ?? 'M-Pesa phone';
      case 'mpesa_till':
        return 'Till ${mpesaTill ?? ''}';
      case 'mpesa_paybill':
        return 'Paybill ${mpesaPaybill ?? ''}';
      case 'bank_account':
        return '${bankName ?? 'Bank'} · ${bankAccountNumber ?? ''}';
      default:
        return destinationType;
    }
  }

  factory PayoutDestination.fromJson(Map<String, dynamic> json) {
    return PayoutDestination(
      id: json['id']?.toString() ?? '',
      destinationType: (json['destination_type'] as String?) ??
          (json['destinationType'] as String?) ??
          '',
      mpesaPhone: json['mpesa_phone'] as String? ?? json['mpesaPhone'] as String?,
      mpesaTill:
          json['mpesa_till_number'] as String? ?? json['mpesaTillNumber'] as String?,
      mpesaPaybill: json['mpesa_paybill_number'] as String? ??
          json['mpesaPaybillNumber'] as String?,
      bankName: json['bank_name'] as String? ?? json['bankName'] as String?,
      bankAccountNumber: json['bank_account_number'] as String? ??
          json['bankAccountNumber'] as String?,
      verified: json['verified'] == true,
      isActive: json['is_active'] != false && json['isActive'] != false,
    );
  }
}

final payoutDestinationsProvider =
    FutureProvider.autoDispose<List<PayoutDestination>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json =
      await ref.watch(mobileApiRepositoryProvider).listPayoutDestinations();
  final raw = json['destinations'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => PayoutDestination.fromJson(Map<String, dynamic>.from(e)))
      .where((d) => d.id.isNotEmpty)
      .toList();
});

final payoutBatchesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  final json = await ref.watch(mobileApiRepositoryProvider).listPayoutBatches();
  final raw = json['batches'] ?? json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class PayoutSettingsPage extends ConsumerStatefulWidget {
  const PayoutSettingsPage({super.key});

  @override
  ConsumerState<PayoutSettingsPage> createState() => _PayoutSettingsPageState();
}

class _PayoutSettingsPageState extends ConsumerState<PayoutSettingsPage> {
  var _type = 'mpesa_phone';
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _tillCtrl = TextEditingController();
  final _paybillCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  var _busy = false;
  var _otpVerified = false;
  String? _message;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _tillCtrl.dispose();
    _paybillCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (!isKenyanMpesaPhone(phone)) {
      setState(() => _message = 'Enter a valid Safaricom number.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _otpVerified = false;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).requestPayoutPhoneOtp(phone);
      setState(() => _message = 'OTP sent to your account email. Enter it below.');
    } catch (e) {
      setState(() {
        _message = e is AppFailure ? e.message : 'Could not send OTP.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmOtp() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).confirmPayoutPhoneOtp(
            phone: _phoneCtrl.text.trim(),
            code: _otpCtrl.text.trim(),
          );
      setState(() {
        _otpVerified = true;
        _message = 'Phone verified. You can save the destination.';
      });
    } catch (e) {
      setState(() {
        _otpVerified = false;
        _message = e is AppFailure ? e.message : 'Invalid code.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final body = <String, dynamic>{'destinationType': _type};
      if (_type == 'mpesa_phone') {
        if (!_otpVerified) {
          setState(() {
            _busy = false;
            _message = 'Verify OTP before saving.';
          });
          return;
        }
        body['mpesaPhone'] = _phoneCtrl.text.trim();
        body['otpVerified'] = true;
      } else if (_type == 'mpesa_till') {
        body['mpesaTillNumber'] = _tillCtrl.text.trim();
      } else if (_type == 'mpesa_paybill') {
        body['mpesaPaybillNumber'] = _paybillCtrl.text.trim();
        body['mpesaAccountNumber'] = _accountCtrl.text.trim();
      }

      await ref.read(mobileApiRepositoryProvider).createPayoutDestination(body);
      ref.invalidate(payoutDestinationsProvider);
      setState(() {
        _message = 'Destination saved.';
        _otpVerified = false;
        _otpCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _message = e is AppFailure ? e.message : 'Could not save destination.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deactivate(PayoutDestination d) async {
    try {
      await ref
          .read(mobileApiRepositoryProvider)
          .deactivatePayoutDestination(d.id);
      ref.invalidate(payoutDestinationsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AppFailure ? e.message : 'Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);
    final async = ref.watch(payoutDestinationsProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payouts')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/landlord/payouts')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payout destinations')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Where rent payouts should go',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: const [
              DropdownMenuItem(value: 'mpesa_phone', child: Text('M-Pesa phone')),
              DropdownMenuItem(value: 'mpesa_till', child: Text('M-Pesa till')),
              DropdownMenuItem(value: 'mpesa_paybill', child: Text('M-Pesa paybill')),
            ],
            onChanged: _busy
                ? null
                : (v) => setState(() {
                      _type = v ?? _type;
                      _otpVerified = false;
                    }),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 12),
          if (_type == 'mpesa_phone') ...[
            TextField(
              controller: _phoneCtrl,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'M-Pesa phone'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _sendOtp,
                    child: const Text('Send OTP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _otpCtrl,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: '6-digit OTP'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _confirmOtp,
              child: const Text('Confirm OTP'),
            ),
          ],
          if (_type == 'mpesa_till')
            TextField(
              controller: _tillCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Till number'),
            ),
          if (_type == 'mpesa_paybill') ...[
            TextField(
              controller: _paybillCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Paybill number'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accountCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Account number'),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save destination'),
          ),
          const SizedBox(height: 28),
          Text(
            'Saved destinations',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          AsyncScaffoldBody(
            async: async,
            onRetry: () => ref.invalidate(payoutDestinationsProvider),
            builder: (items) {
              if (items.isEmpty) return const Text('None yet.');
              return Column(
                children: items
                    .map(
                      (d) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(d.summary),
                        subtitle: Text(
                          '${d.destinationType}${d.verified ? ' · verified' : ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deactivate(d),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Recent payout batches',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          AsyncScaffoldBody(
            async: ref.watch(payoutBatchesProvider),
            onRetry: () => ref.invalidate(payoutBatchesProvider),
            builder: (batches) {
              if (batches.isEmpty) return const Text('No batches yet.');
              return Column(
                children: batches.map((b) {
                  final status = (b['status'] as String?) ?? '';
                  final amount = (b['total_amount'] as num?)?.toInt() ??
                      (b['amount'] as num?)?.toInt() ??
                      (b['totalAmount'] as num?)?.toInt();
                  final created = (b['created_at'] as String?) ??
                      (b['createdAt'] as String?) ??
                      '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(
                      amount != null ? 'KES $amount' : 'Batch',
                    ),
                    subtitle: Text(
                      [
                        if (status.isNotEmpty) status,
                        if (created.isNotEmpty) created,
                      ].join(' · '),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
