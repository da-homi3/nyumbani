import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/presentation/contact_unlock_card.dart'
    show isKenyanMpesaPhone;
import 'package:nyumbasearch/features/tenants/data/tenants_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

class RentPage extends ConsumerStatefulWidget {
  const RentPage({super.key});

  @override
  ConsumerState<RentPage> createState() => _RentPageState();
}

class _RentPageState extends ConsumerState<RentPage> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _smsCtrl = TextEditingController();
  String? _payingId;
  String? _smsInvoiceId;
  var _busy = false;
  String? _localError;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _smsCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(tenantRentAccessProvider);
    ref.invalidate(tenantRentInvoicesProvider);
    await Future.wait([
      ref.read(tenantRentAccessProvider.future),
      ref.read(tenantRentInvoicesProvider.future),
    ]);
  }

  Future<void> _submitSms(RentInvoice invoice) async {
    final sms = _smsCtrl.text.trim();
    if (sms.length < 20) {
      setState(() => _localError = 'Paste the full M-Pesa confirmation SMS.');
      return;
    }
    setState(() {
      _busy = true;
      _localError = null;
    });
    try {
      await ref.read(tenantsRepositoryProvider).submitRentSmsClaim(
            invoiceId: invoice.id,
            smsText: sms,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rent credited from M-Pesa SMS.')),
        );
      }
      setState(() {
        _smsInvoiceId = null;
        _smsCtrl.clear();
      });
      await _refresh();
    } catch (e) {
      setState(() {
        _localError = e is AppFailure ? e.message : 'Could not process SMS.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay(RentInvoice invoice) async {
    final phone = _phoneCtrl.text.trim();
    if (!isKenyanMpesaPhone(phone)) {
      setState(() => _localError = 'Enter a valid Kenyan M-Pesa number (e.g. 07XX XXX XXX).');
      return;
    }
    final amount = int.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _localError = 'Enter a valid amount to pay.');
      return;
    }
    if (amount > invoice.balanceRemaining) {
      setState(() => _localError = 'Amount cannot exceed the remaining balance.');
      return;
    }

    setState(() {
      _busy = true;
      _localError = null;
    });

    try {
      final idPrefix =
          invoice.id.length >= 8 ? invoice.id.substring(0, 8) : invoice.id;
      final key =
          'rent-$idPrefix-$amount-${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref.read(tenantsRepositoryProvider).payRent(
            invoiceId: invoice.id,
            phone: phone,
            amountKes: amount,
            idempotencyKey: key.length > 64 ? key.substring(0, 64) : key,
          );

      if (result.isCompleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rent paid successfully.')),
          );
        }
        setState(() => _payingId = null);
        await _refresh();
        return;
      }

      final paymentId = result.paymentId;
      if (paymentId == null || paymentId.isEmpty) {
        setState(() => _localError = result.message ?? 'Could not start M-Pesa STK.');
        return;
      }

      final ok = await _showStkDialog(
        paymentId: paymentId,
        message: result.message ??
            'STK push sent. Enter your M-Pesa PIN on your phone to confirm.',
      );
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment confirmed.')),
          );
        }
        setState(() => _payingId = null);
        await _refresh();
      }
    } catch (e) {
      setState(() {
        _localError = e is AppFailure ? e.message : 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _showStkDialog({required String paymentId, required String message}) async {
    if (!mounted) return false;
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RentStkWaitingDialog(
        paymentId: paymentId,
        initialMessage: message,
      ),
    );
    return completed == true;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              NyumbaTokens.shellBottomInset(context),
            ),
            children: [
              Text(
                'Your rent',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pay with M-Pesa in the app, paste an M-Pesa SMS you already paid with, or record cash/bank.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              _RentLink(
                label: 'File a complaint →',
                onTap: () => context.push('/complaints'),
              ),
              _RentLink(
                label: 'Maintenance →',
                onTap: () => context.push('/maintenance'),
              ),
              const SizedBox(height: 20),
              const _RentEmptyBox(
                message:
                    'Sign in to see rent invoices. Ask your landlord to invite you to the tenancy portal.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(loginLocation(from: '/rent')),
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/profile'),
                  child: Text(
                    'Account settings',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final accessAsync = ref.watch(tenantRentAccessProvider);
    final invoicesAsync = ref.watch(tenantRentInvoicesProvider);

    Widget rentHeader({required String emptyMessage}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your rent',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pay with M-Pesa in the app, paste an M-Pesa SMS you already paid with, or record cash/bank.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _RentLink(
            label: 'File a complaint →',
            onTap: () => context.push('/complaints'),
          ),
          _RentLink(
            label: 'Maintenance →',
            onTap: () => context.push('/maintenance'),
          ),
          const SizedBox(height: 20),
          _RentEmptyBox(message: emptyMessage),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.push('/profile'),
              child: Text(
                'Account settings',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: accessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) {
            final msg = err is AppFailure ? err.message : 'Could not load rent access.';
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                NyumbaTokens.shellBottomInset(context),
              ),
              children: [
                Text(msg),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            );
          },
          data: (access) {
            if (!access.linked) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  NyumbaTokens.shellBottomInset(context),
                ),
                children: [
                  rentHeader(
                    emptyMessage:
                        'No rent invoices yet. Ask your landlord to invite you to the tenancy portal.',
                  ),
                ],
              );
            }
            if (!access.hasActiveLease) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  NyumbaTokens.shellBottomInset(context),
                ),
                children: [
                  rentHeader(
                    emptyMessage:
                        'Your account is linked, but there is no active lease yet.',
                  ),
                ],
              );
            }

            return invoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) {
                final msg = err is AppFailure ? err.message : 'Could not load invoices.';
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    NyumbaTokens.shellBottomInset(context),
                  ),
                  children: [
                    Text(msg),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                );
              },
              data: (invoices) {
                if (invoices.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      NyumbaTokens.shellBottomInset(context),
                    ),
                    children: [
                      ..._leaseSection(theme, access.leases),
                      rentHeader(
                        emptyMessage: access.hasActiveLease
                            ? (access.invoiceCount > 0
                                ? 'Invoices are being prepared. Pull to refresh in a moment.'
                                : 'Your lease is active. Rent invoices will appear here shortly — pull to refresh.')
                            : 'No rent invoices yet. Ask your landlord to invite you to the tenancy portal.',
                      ),
                    ],
                  );
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    NyumbaTokens.shellBottomInset(context),
                  ),
                  children: [
                    ..._leaseSection(theme, access.leases),
                    for (var i = 0; i < invoices.length; i++) ...[
                      if (i > 0 || access.leases.isNotEmpty) const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final inv = invoices[i];
                          final paying = _payingId == inv.id;
                          return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              inv.title,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (inv.periodMonth.isNotEmpty) inv.periodMonth,
                                if (inv.dueDate.isNotEmpty) 'Due ${inv.dueDate}',
                              ].join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Chip(
                                  label: Text(inv.isPaid ? 'Paid' : inv.status.replaceAll('_', ' ')),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Spacer(),
                                Text(
                                  inv.isPaid
                                      ? 'Settled'
                                      : 'Balance KES ${inv.balanceRemaining}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (!inv.isPaid) ...[
                              const SizedBox(height: 12),
                              if (_smsInvoiceId == inv.id) ...[
                                TextField(
                                  controller: _smsCtrl,
                                  enabled: !_busy,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    labelText: 'Paste M-Pesa SMS',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                if (_localError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _localError!,
                                    style: TextStyle(color: theme.colorScheme.error),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _busy
                                            ? null
                                            : () => setState(() {
                                                  _smsInvoiceId = null;
                                                  _localError = null;
                                                }),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: _busy ? null : () => _submitSms(inv),
                                        child: _busy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text('Submit SMS'),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (!paying) ...[
                                FilledButton(
                                  onPressed: _busy
                                      ? null
                                      : () {
                                          setState(() {
                                            _payingId = inv.id;
                                            _smsInvoiceId = null;
                                            _localError = null;
                                            _phoneCtrl.text = inv.defaultMpesaPhone ?? '';
                                            _amountCtrl.text = '${inv.balanceRemaining}';
                                          });
                                        },
                                  child: const Text('Pay with M-Pesa'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() {
                                            _smsInvoiceId = inv.id;
                                            _payingId = null;
                                            _localError = null;
                                            _smsCtrl.clear();
                                          }),
                                  child: const Text('I already paid (paste SMS)'),
                                ),
                              ] else ...[
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
                                  controller: _amountCtrl,
                                  enabled: !_busy,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Amount (KES)',
                                    helperText: 'Max KES ${inv.balanceRemaining}',
                                    prefixIcon: const Icon(Icons.payments_outlined),
                                  ),
                                ),
                                if (_localError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(_localError!, style: TextStyle(color: theme.colorScheme.error)),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _busy
                                            ? null
                                            : () => setState(() {
                                                  _payingId = null;
                                                  _localError = null;
                                                }),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: _busy ? null : () => _pay(inv),
                                        child: _busy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Pay'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                        },
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _leaseSection(ThemeData theme, List<TenantLease> leases) {
    final active = leases.where((l) => l.isActive).toList();
    final shown = active.isNotEmpty ? active : leases.take(1).toList();
    if (shown.isEmpty) return const [];
    return [
      Text(
        shown.length == 1 ? 'Your lease' : 'Your leases',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      for (final lease in shown) ...[
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  lease.isActive ? 'Active lease' : 'Past lease',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lease.placeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (lease.neighborhood != null && lease.neighborhood!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    lease.neighborhood!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'KES ${lease.monthlyRent}/mo',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (lease.startDate.isNotEmpty) 'Starts ${lease.startDate}',
                    if (lease.endDate.isNotEmpty) 'Ends ${lease.endDate}',
                    if (lease.depositPaid > 0) 'Deposit KES ${lease.depositPaid}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _RentLink extends StatelessWidget {
  const _RentLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: NyumbaTokens.primaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _RentEmptyBox extends StatelessWidget {
  const _RentEmptyBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: theme.colorScheme.outline.withValues(alpha: 0.45),
        radius: 16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 5.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _RentStkWaitingDialog extends ConsumerStatefulWidget {
  const _RentStkWaitingDialog({
    required this.paymentId,
    required this.initialMessage,
  });

  final String paymentId;
  final String initialMessage;

  @override
  ConsumerState<_RentStkWaitingDialog> createState() => _RentStkWaitingDialogState();
}

class _RentStkWaitingDialogState extends ConsumerState<_RentStkWaitingDialog> {
  late String _message = widget.initialMessage;
  var _done = false;
  var _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _poll());
  }

  Future<void> _poll() async {
    final repo = ref.read(tenantsRepositoryProvider);
    try {
      final result = await repo.waitForPayment(widget.paymentId);
      if (!mounted) return;
      setState(() {
        _message = result.isCompleted
            ? 'Payment confirmed.'
            : result.message;
        _done = true;
        _success = result.isCompleted;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(context).pop(_success);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not confirm STK payment. Close and try again.';
        _done = true;
        _success = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('M-Pesa STK'),
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
