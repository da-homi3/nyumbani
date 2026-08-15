import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nyumbasearch/core/analytics/analytics_client.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/brand_logo.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with WidgetsBindingObserver {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  var _googleAwaitingBrowser = false;
  String? _error;

  String? get _from {
    final q = GoRouterState.of(context).uri.queryParameters['from'];
    return (q != null && q.isNotEmpty) ? q : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_googleAwaitingBrowser) return;
    final session = ref.read(supabaseClientProvider)?.auth.currentSession;
    if (session != null && mounted) {
      setState(() {
        _busy = false;
        _googleAwaitingBrowser = false;
      });
      _goAfterAuth();
    }
  }

  void _goAfterAuth() {
    if (!mounted) return;
    navigateAfterAuth(context, from: _from);
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithEmail(
            email: email,
            password: _password.text,
          );
      _goAfterAuth();
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not sign in. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _googleAwaitingBrowser = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      // Session arrives via deep link → authSessionProvider listener.
      // Soft-release busy so email form works while waiting for browser return.
      if (mounted && _googleAwaitingBrowser) {
        setState(() => _busy = false);
      }
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Google sign-in failed.';
        _busy = false;
        _googleAwaitingBrowser = false;
      });
    }
  }

  void _cancelGoogleWait() {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _googleAwaitingBrowser = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Session?>>(authSessionProvider, (prev, next) {
      final session = next.valueOrNull;
      if (session != null && mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        if (prev?.valueOrNull == null && _googleAwaitingBrowser) {
          ref.read(analyticsProvider).track(AnalyticsEvents.loginCompleted, {'method': 'google'});
        }
        setState(() {
          _busy = false;
          _googleAwaitingBrowser = false;
        });
        _goAfterAuth();
      }
    });

    final formBusy = _busy && !_googleAwaitingBrowser;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandLogo(height: 26, markOnly: true),
            SizedBox(width: 10),
            Text('Sign in'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const BrandLogo(height: 36),
          const SizedBox(height: 20),
          Text(
            'Welcome back',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Use your existing NyumbaSearch account.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            enabled: !formBusy,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(labelText: 'Password'),
            onSubmitted: (_) => formBusy ? null : _submit(),
            enabled: !formBusy,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_googleAwaitingBrowser) ...[
            const SizedBox(height: 12),
            Text(
              'Finish signing in with Google in your browser, then return here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _cancelGoogleWait,
                child: const Text('Cancel Google sign-in'),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: formBusy ? null : _submit,
            child: formBusy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sign in'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: formBusy ? null : _google,
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: Text(_googleAwaitingBrowser ? 'Waiting for Google…' : 'Continue with Google'),
          ),
          TextButton(
            onPressed: formBusy
                ? null
                : () {
                    final from = _from;
                    final loc = from == null
                        ? '/signup'
                        : Uri(path: '/signup', queryParameters: {'from': from}).toString();
                    context.push(loc);
                  },
            child: const Text('Create a tenant account'),
          ),
          TextButton(
            onPressed: formBusy
                ? null
                : () {
                    final email = _email.text.trim();
                    final loc = email.isEmpty
                        ? '/auth/reset'
                        : Uri(
                            path: '/auth/reset',
                            queryParameters: {'email': email},
                          ).toString();
                    context.push(loc);
                  },
            child: const Text('Forgot password?'),
          ),
        ],
      ),
    );
  }
}
