import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/verification/presentation/verification_pipeline.dart';
import 'package:nyumbasearch/shared/widgets/nyumba_app_bar.dart';

class PasswordResetPage extends ConsumerStatefulWidget {
  const PasswordResetPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  late final TextEditingController _emailCtrl;
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  var _step = 0; // 0 request, 1 verify, 2 complete
  var _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Enter a valid email.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).requestPasswordResetOtp(email);
      if (!mounted) return;
      setState(() {
        _step = 1;
        _message = 'If that email exists, a 6-digit code was sent.';
      });
    } catch (e) {
      setState(() {
        _message = e is AppFailure ? e.message : 'Could not send code.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _message = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).verifyPasswordResetOtp(
            email: email,
            code: code,
          );
      if (!mounted) return;
      setState(() {
        _step = 2;
        _message = 'Code verified. Choose a new password.';
      });
    } catch (e) {
      setState(() {
        _message = e is AppFailure ? e.message : 'Invalid or expired code.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (password.length < 8) {
      setState(() => _message = 'Password must be at least 8 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).completePasswordResetOtp(
            email: email,
            code: code,
            password: password,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Sign in.')),
      );
      context.go('/login');
    } catch (e) {
      setState(() {
        _message = e is AppFailure ? e.message : 'Could not reset password.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const NyumbaAppBar(title: 'Reset password'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          VerificationPipeline(
            activeStep: _step,
            steps: const ['Email', 'Code', 'Password'],
          ),
          const SizedBox(height: 20),
          Text(
            _step == 0
                ? 'Enter your email'
                : _step == 1
                    ? 'Enter the code from email'
                    : 'Set a new password',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            enabled: !_busy && _step == 0,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          if (_step >= 1) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              enabled: !_busy && _step == 1,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(labelText: '6-digit code'),
            ),
          ],
          if (_step >= 2) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    if (_step == 0) {
                      _request();
                    } else if (_step == 1) {
                      _verify();
                    } else {
                      _complete();
                    }
                  },
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _step == 0
                        ? 'Send code'
                        : _step == 1
                            ? 'Verify code'
                            : 'Update password',
                  ),
          ),
          if (_step > 0)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _step = 0;
                        _message = null;
                      }),
              child: const Text('Start over'),
            ),
        ],
      ),
    );
  }
}
