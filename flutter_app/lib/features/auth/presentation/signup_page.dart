import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/analytics/analytics_client.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/presentation/contact_unlock_card.dart'
    show isKenyanMpesaPhone;
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/brand_logo.dart';
import 'package:nyumbasearch/shared/widgets/nyumba_app_bar.dart';

const _roles = <({String id, String label})>[
  (id: 'tenant', label: 'Tenant'),
  (id: 'landlord', label: 'Landlord'),
  (id: 'agency', label: 'Agency'),
  (id: 'manager', label: 'Manager'),
];

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _name = TextEditingController();
  final _org = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _role = 'tenant';
  var _busy = false;
  var _otpSent = false;
  var _phoneVerified = false;
  String? _error;
  String? _info;

  bool get _privileged =>
      _role == 'landlord' || _role == 'agency' || _role == 'manager';

  String? get _from {
    final q = GoRouterState.of(context).uri.queryParameters['from'];
    return (q != null && q.isNotEmpty) ? q : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _org.dispose();
    _phone.dispose();
    _otp.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final phone = _phone.text.trim();
    if (!isKenyanMpesaPhone(phone)) {
      setState(() => _error = 'Enter a valid Kenyan mobile (07XX XXX XXX).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
      _phoneVerified = false;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).requestPhoneOtp(phone);
      setState(() {
        _otpSent = true;
        _info = 'OTP sent by SMS. Enter the code to verify your phone.';
      });
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not send OTP.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(mobileApiRepositoryProvider).verifyPhoneOtp(
            phone: _phone.text.trim(),
            code: _otp.text.trim(),
          );
      setState(() {
        _phoneVerified = true;
        _info = 'Phone verified.';
      });
    } catch (e) {
      setState(() {
        _phoneVerified = false;
        _error = e is AppFailure ? e.message : 'Invalid code.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter your full name.');
      return;
    }
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _error = 'Enter a valid email.');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_privileged && _org.text.trim().length < 2) {
      setState(() => _error = 'Enter your organization or business name.');
      return;
    }
    final phone = _phone.text.trim();
    if (_privileged) {
      if (!isKenyanMpesaPhone(phone)) {
        setState(() => _error = 'Portal signup requires a verified Kenyan phone.');
        return;
      }
      if (!_phoneVerified) {
        setState(() => _error = 'Verify your phone with OTP before continuing.');
        return;
      }
    } else if (phone.isNotEmpty && !_phoneVerified) {
      setState(() => _error = 'Verify your phone with OTP, or clear the phone field.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    ref.read(analyticsProvider).track(AnalyticsEvents.signupStarted, {'role': _role});
    try {
      final hasSession = await ref.read(authControllerProvider.notifier).signUpWithEmail(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            phone: phone.isEmpty ? null : phone,
            accountRole: _role,
            organizationName: _privileged ? _org.text.trim() : null,
          );
      if (!mounted) return;
      if (!hasSession) {
        setState(() {
          _info = _privileged
              ? 'Account created. Confirm your email, then sign in — we will show your pending application.'
              : 'Account created. Check your email to confirm, then sign in.';
        });
        return;
      }

      if (_privileged) {
        try {
          await ref.read(mobileApiRepositoryProvider).portalApply({
            'requestedRole': _role,
            'organizationName': _org.text.trim(),
            'phone': phone,
          });
        } catch (e) {
          // Account exists; still send user to pending so they can retry apply.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e is AppFailure
                      ? e.message
                      : 'Signed up — complete portal application next.',
                ),
              ),
            );
          }
        }
        if (!mounted) return;
        context.go('/auth/pending');
        return;
      }

      navigateAfterAuth(context, from: _from);
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not create account.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const NyumbaAppBar(title: 'Create account'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const BrandLogo(height: 36),
          const SizedBox(height: 20),
          Text(
            'Join NyumbaSearch',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your account to save homes, unlock contacts, and manage tenancy.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Text('I am a', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _roles)
                ChoiceChip(
                  label: Text(r.label),
                  selected: _role == r.id,
                  onSelected: _busy
                      ? null
                      : (v) {
                          if (v) setState(() => _role = r.id);
                        },
                ),
            ],
          ),
          if (_privileged) ...[
            const SizedBox(height: 12),
            Text(
              'Lister accounts need approval. After signup you will wait on the pending screen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _org,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Organization / business name',
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            enabled: !_busy && !_phoneVerified,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: _privileged
                  ? 'Phone (required, verified via SMS)'
                  : 'Phone (optional, verified via SMS)',
              hintText: '07XX XXX XXX',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy || _phoneVerified ? null : _requestOtp,
                  child: Text(_otpSent ? 'Resend OTP' : 'Send OTP'),
                ),
              ),
            ],
          ),
          if (_otpSent && !_phoneVerified) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _otp,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'SMS code'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _verifyOtp,
              child: const Text('Verify phone'),
            ),
          ],
          if (_phoneVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Phone verified',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_info != null) ...[
            const SizedBox(height: 12),
            Text(_info!, style: TextStyle(color: theme.colorScheme.primary)),
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
                : Text(_privileged ? 'Apply & create account' : 'Create account'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    final from = _from;
                    context.go(loginLocation(from: from));
                  },
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}
