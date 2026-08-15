import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/caretaker/data/caretaker_session_store.dart';

class CaretakerLoginPage extends ConsumerStatefulWidget {
  const CaretakerLoginPage({super.key});

  @override
  ConsumerState<CaretakerLoginPage> createState() => _CaretakerLoginPageState();
}

class _CaretakerLoginPageState extends ConsumerState<CaretakerLoginPage> {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _busy = false;
  String? _message;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final json = await ref.read(mobileApiRepositoryProvider).caretakerSession(
            phone: _phoneCtrl.text.trim(),
            pin: _pinCtrl.text.trim(),
          );
      final token = (json['token'] as String?)?.trim() ?? '';
      if (token.isEmpty) {
        throw const ServerFailure('Caretaker session token missing');
      }
      final name = json['caretakerName'] as String? ??
          json['caretaker_name'] as String?;
      await caretakerSessionStore.save(token: token, name: name);
      if (!mounted) return;
      context.go('/caretaker/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e is AppFailure ? e.message : 'Could not sign in. Check phone and PIN.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Caretaker login')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Sign in with phone and PIN',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Caretakers use a separate PIN login (not the tenant email account).',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _phoneCtrl,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Phone',
                hintText: '07XX XXX XXX',
                prefixIcon: Icon(Icons.phone_android),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.length < 9) return 'Enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pinCtrl,
              enabled: !_busy,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.length < 4) return 'Enter your PIN';
                return null;
              },
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
