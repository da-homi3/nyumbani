import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/profile/data/me_providers.dart';
import 'package:nyumbasearch/features/properties/data/unlock_models.dart';
import 'package:nyumbasearch/features/properties/presentation/contact_unlock_card.dart'
    show isKenyanMpesaPhone;
import 'package:nyumbasearch/features/verification/presentation/verification_pipeline.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

const _tiers = <({String id, String label, int kes})>[
  (id: 'basic', label: 'Basic', kes: 1000),
  (id: 'standard', label: 'Standard', kes: 2500),
  (id: 'express', label: 'Express', kes: 5000),
];

class VerifyRequestPage extends ConsumerStatefulWidget {
  const VerifyRequestPage({super.key});

  @override
  ConsumerState<VerifyRequestPage> createState() => _VerifyRequestPageState();
}

class _VerifyRequestPageState extends ConsumerState<VerifyRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _listingCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _tier = 'standard';
  var _busy = false;
  var _paying = false;
  String? _error;
  String? _createdId;
  int? _createdFee;

  int get _selectedFee =>
      _tiers.firstWhere((t) => t.id == _tier, orElse: () => _tiers[1]).kes;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _listingCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(authSessionProvider).valueOrNull;
      final me = ref.read(meProvider).valueOrNull;
      if (session?.user.email != null && _emailCtrl.text.isEmpty) {
        _emailCtrl.text = session!.user.email!;
      }
      if (me?.fullName != null && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = me!.fullName!;
      }
      if (me?.phone != null && _phoneCtrl.text.isEmpty) {
        _phoneCtrl.text = me!.phone!;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final json = await ref.read(mobileApiRepositoryProvider).createVerificationRequest({
        'propertyAddress': _addressCtrl.text.trim(),
        'listingUrl': _listingCtrl.text.trim().isEmpty ? null : _listingCtrl.text.trim(),
        'tier': _tier,
        'requesterName': _nameCtrl.text.trim(),
        'requesterPhone': _phoneCtrl.text.trim(),
        'requesterEmail': _emailCtrl.text.trim(),
      });
      final req = json['request'];
      final id = req is Map ? req['id']?.toString() : json['id']?.toString();
      final fee = req is Map
          ? (req['amount_paid_kes'] as num?)?.toInt()
          : (json['amount_paid_kes'] as num?)?.toInt();
      setState(() {
        _createdId = id;
        _createdFee = fee ?? _selectedFee;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request created. Pay to start the check.')),
      );
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not submit request.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay({required String method}) async {
    final id = _createdId;
    if (id == null) return;

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (method == 'mpesa' && !isKenyanMpesaPhone(phone)) {
      setState(() => _error = 'Enter a valid Kenyan M-Pesa number to pay.');
      return;
    }

    setState(() {
      _paying = true;
      _error = null;
    });

    try {
      final json = await ref.read(mobileApiRepositoryProvider).payVerificationRequest(
            id,
            paymentMethod: method,
            phoneNumber: phone,
            email: email.isEmpty ? null : email,
            idempotencyKey: 'verify-$method-${id.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch}',
          );
      final result = UnlockActionResult.fromJson({
        'unlocked': false,
        'status': json['status'],
        'paymentId': json['paymentId'],
        'message': json['message'],
        'redirectUrl': json['redirectUrl'],
      });

      if (json['status'] == 'completed') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment confirmed.')),
        );
        context.push('/verify/$id');
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
        setState(() => _error = result.message ?? 'Could not start payment.');
        return;
      }

      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _VerifyPayDialog(
          paymentId: paymentId,
          title: method == 'card' ? 'Card payment' : 'M-Pesa STK',
          initialMessage: result.message ??
              (method == 'card'
                  ? 'Complete payment in the browser, then return here.'
                  : 'Enter your M-Pesa PIN on your phone.'),
        ),
      );
      if (!mounted) return;
      if (ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment confirmed.')),
        );
        context.push('/verify/$id');
      }
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Payment failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verify a property')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/verify')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    if (_createdId != null) {
      final fee = _createdFee ?? _selectedFee;
      return Scaffold(
        appBar: AppBar(title: const Text('Verify a property')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const VerificationPipeline(activeStep: 1),
            const SizedBox(height: 20),
            Text(
              'Complete payment',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Reference: $_createdId\nAmount due: KES $fee',
              style: theme.textTheme.bodyMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _paying ? null : () => _pay(method: 'mpesa'),
              child: _paying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Pay KES $fee via M-Pesa STK'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _paying ? null : () => _pay(method: 'card'),
              icon: const Icon(Icons.credit_card),
              label: Text('Pay KES $fee by card'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push('/verify/$_createdId'),
              child: const Text('View status'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Back to profile'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verify a property')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const VerificationPipeline(activeStep: 0),
            const SizedBox(height: 20),
            Text(
              'Request an authenticity check',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a tier and submit your request. You will pay with M-Pesa or card next.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tier',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final t in _tiers) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: _tier == t.id
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _tier = t.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            _tier == t.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            'KES ${t.kes}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Property address',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Enter the address' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _listingCtrl,
              decoration: const InputDecoration(
                labelText: 'Listing URL (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Name required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (Kenya)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 9) ? 'Phone required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email required' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifyPayDialog extends ConsumerStatefulWidget {
  const _VerifyPayDialog({
    required this.paymentId,
    required this.initialMessage,
    required this.title,
  });

  final String paymentId;
  final String initialMessage;
  final String title;

  @override
  ConsumerState<_VerifyPayDialog> createState() => _VerifyPayDialogState();
}

class _VerifyPayDialogState extends ConsumerState<_VerifyPayDialog> {
  late String _message = widget.initialMessage;
  var _done = false;
  var _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final deadline = DateTime.now().add(const Duration(minutes: 2));
      var last = PaymentPollStatus.fromJson(
        await ref.read(mobileApiRepositoryProvider).paymentStatus(widget.paymentId),
      );
      while (DateTime.now().isBefore(deadline)) {
        if (last.isCompleted || last.isFailed) break;
        await Future<void>.delayed(const Duration(seconds: 3));
        last = PaymentPollStatus.fromJson(
          await ref.read(mobileApiRepositoryProvider).paymentStatus(widget.paymentId),
        );
      }
      if (!mounted) return;
      setState(() {
        _message = last.isCompleted ? 'Payment confirmed.' : last.message;
        _done = true;
        _success = last.isCompleted;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(context).pop(_success);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not confirm payment.';
        _done = true;
        _success = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_done) const CircularProgressIndicator(),
          if (_done && _success)
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary, size: 40),
          const SizedBox(height: 16),
          Text(_message, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(_done ? 'Close' : 'Cancel'),
        ),
      ],
    );
  }
}

class VerifyStatusPage extends ConsumerWidget {
  const VerifyStatusPage({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verification status')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/verify/$requestId')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(_verifyStatusProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Verification status')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          final msg = err is AppFailure ? err.message : 'Could not load status.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(_verifyStatusProvider(requestId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (row) {
          final status = (row['status'] as String?) ?? '';
          final step = verificationPipelineStep(status);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              VerificationPipeline(activeStep: step),
              const SizedBox(height: 20),
              Text(
                (row['property_address'] as String?) ?? 'Verification request',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _row('Status', status.isEmpty ? '—' : status),
              _row('Tier', (row['tier'] as String?) ?? '—'),
              _row(
                'Amount',
                row['amount_paid_kes'] != null ? 'KES ${row['amount_paid_kes']}' : '—',
              ),
              if (row['listing_url'] != null)
                _row('Listing', row['listing_url'].toString()),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

final _verifyStatusProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final json = await ref.watch(mobileApiRepositoryProvider).verificationRequest(id);
  final req = json['request'];
  if (req is Map) return Map<String, dynamic>.from(req);
  return json;
});
