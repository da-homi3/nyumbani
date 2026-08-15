import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nyumbasearch/core/utils/app_log.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/brand_logo.dart';

/// Landing surface for `ke.co.nyumbasearch.app://login-callback/` (OAuth / reset).
class OAuthCallbackPage extends ConsumerStatefulWidget {
  const OAuthCallbackPage({super.key, this.uri});

  final Uri? uri;

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  String? _error;
  var _busy = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      setState(() {
        _busy = false;
        _error = 'Supabase is not configured on this build.';
      });
      return;
    }

    try {
      final uri = widget.uri ?? GoRouterState.of(context).uri;
      // PKCE: Supabase may already have exchanged via deep-link listener;
      // still try explicit recovery when the URL carries tokens/code.
      final hasAuthPayload = uri.queryParameters.containsKey('code') ||
          uri.fragment.contains('access_token') ||
          uri.queryParameters.containsKey('access_token');
      if (hasAuthPayload) {
        try {
          await client.auth.getSessionFromUrl(uri);
        } catch (e) {
          AppLog.w('getSessionFromUrl: $e');
        }
      }

      // Brief wait for onAuthStateChange after browser return.
      for (var i = 0; i < 12; i++) {
        final session = client.auth.currentSession;
        if (session != null) {
          if (!mounted) return;
          navigateAfterAuth(context);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'Could not finish Google sign-in. Return to login and try again, '
            'or confirm the redirect URL is allowlisted in Supabase.';
      });
    } catch (e) {
      AppLog.w('OAuth callback failed: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is AuthException ? e.message : 'Sign-in callback failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Session?>>(authSessionProvider, (prev, next) {
      if (next.valueOrNull != null && mounted) {
        navigateAfterAuth(context);
      }
    });

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(height: 40),
              const SizedBox(height: 24),
              if (_busy) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Completing sign-in…',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ] else ...[
                Text(
                  _error ?? 'Signed out',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to sign in'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
