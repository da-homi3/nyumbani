import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/features/properties/data/unlock_models.dart';

typedef PaymentPollCallback = Future<PaymentPollStatus> Function(String paymentId);

/// Polls payment status until complete/failed/timeout. Re-polls immediately when
/// the app returns from an external browser (card checkout).
class PaymentWaitingDialog extends ConsumerStatefulWidget {
  const PaymentWaitingDialog({
    super.key,
    required this.paymentId,
    required this.initialMessage,
    required this.title,
    required this.pollPayment,
    this.successMessage = 'Payment confirmed.',
    this.timeout = stkTimeout,
    this.interval = const Duration(seconds: 3),
  });

  final String paymentId;
  final String initialMessage;
  final String title;
  final String successMessage;
  final PaymentPollCallback pollPayment;
  final Duration timeout;
  final Duration interval;

  static const stkTimeout = Duration(minutes: 2);
  static const cardTimeout = Duration(minutes: 10);

  @override
  ConsumerState<PaymentWaitingDialog> createState() => _PaymentWaitingDialogState();
}

class _PaymentWaitingDialogState extends ConsumerState<PaymentWaitingDialog>
    with WidgetsBindingObserver {
  late String _message;
  var _done = false;
  var _success = false;
  var _pollImmediately = false;
  var _stopped = false;

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pollLoop());
  }

  @override
  void dispose() {
    _stopped = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_done) {
      _pollImmediately = true;
    }
  }

  Future<void> _pollLoop() async {
    final deadline = DateTime.now().add(widget.timeout);
    PaymentPollStatus last;

    try {
      last = await widget.pollPayment(widget.paymentId);
    } catch (_) {
      _finish(success: false, message: 'Could not confirm payment. Close and try again.');
      return;
    }

    while (!_stopped && DateTime.now().isBefore(deadline)) {
      if (last.isCompleted || last.isFailed) break;
      if (mounted) setState(() => _message = last.message);

      if (_pollImmediately) {
        _pollImmediately = false;
      } else {
        await Future<void>.delayed(widget.interval);
      }
      if (_stopped || !mounted) return;

      try {
        last = await widget.pollPayment(widget.paymentId);
      } catch (_) {
        _finish(success: false, message: 'Could not confirm payment. Close and try again.');
        return;
      }
    }

    if (_stopped || !mounted) return;
    _finish(
      success: last.isCompleted,
      message: last.isCompleted ? widget.successMessage : last.message,
    );
  }

  Future<void> _finish({required bool success, required String message}) async {
    if (_stopped || !mounted) return;
    setState(() {
      _message = message;
      _done = true;
      _success = success;
    });
    if (success) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
