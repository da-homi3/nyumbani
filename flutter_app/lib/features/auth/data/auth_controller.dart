import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nyumbasearch/core/analytics/analytics_client.dart';
import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/utils/app_log.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!AppConfig.hasSupabaseKey) return null;
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

/// Session stream seeded with the current session so UI does not flash signed-out.
final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return Stream.value(null);
  return Stream<Session?>.multi((controller) {
    controller.add(client.auth.currentSession);
    final sub = client.auth.onAuthStateChange.listen((event) {
      controller.add(event.session);
    });
    controller.onCancel = sub.cancel;
  });
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<Session?>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<Session?>> {
  AuthController(this._ref) : super(const AsyncValue.loading()) {
    _hydrate();
  }

  final Ref _ref;

  SupabaseClient get _client {
    final c = _ref.read(supabaseClientProvider);
    if (c == null) {
      throw const UnexpectedFailure(
        'Supabase is not configured. Pass --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
    return c;
  }

  Future<void> _hydrate() async {
    try {
      final session = _client.auth.currentSession;
      state = AsyncValue.data(session);
    } catch (e, st) {
      AppLog.e('Auth hydrate failed', e, st);
      state = AsyncValue.data(null);
    }
  }

  /// Wait until hydrate finishes (splash / cold start).
  Future<Session?> waitForHydration({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!state.isLoading) return state.valueOrNull;
    final deadline = DateTime.now().add(timeout);
    while (state.isLoading && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return state.valueOrNull;
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      state = AsyncValue.data(res.session);
      AppLog.i('Signed in ${res.user?.id}');
      _ref.read(analyticsProvider).track(AnalyticsEvents.loginCompleted, {'method': 'email'});
    } on AuthException catch (e, st) {
      AppLog.w('Sign-in failed: ${e.message}');
      state = AsyncValue.error(ServerFailure(e.message), st);
      rethrow;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(e.toString()), st);
      rethrow;
    }
  }

  /// Returns true when a session exists immediately; false if email confirmation is required.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String accountRole = 'tenant',
    String? organizationName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final role = accountRole.trim().isEmpty ? 'tenant' : accountRole.trim();
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          'account_role': role,
          if (organizationName != null && organizationName.trim().isNotEmpty)
            'organization_name': organizationName.trim(),
        },
      );
      state = AsyncValue.data(res.session);
      AppLog.i('Signed up ${res.user?.id} session=${res.session != null}');
      if (res.session != null) {
        _ref.read(analyticsProvider).track(AnalyticsEvents.signupCompleted, {'role': role});
      }
      return res.session != null;
    } on AuthException catch (e, st) {
      AppLog.w('Sign-up failed: ${e.message}');
      state = AsyncValue.error(ServerFailure(e.message), st);
      rethrow;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(e.toString()), st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.oauthRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = const AsyncValue.data(null);
    AppLog.i('Signed out');
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AppConfig.oauthRedirectUrl,
    );
  }

  /// Starts an email change. Supabase emails a confirmation link to the new address.
  Future<void> updateEmail(String email) async {
    final next = email.trim().toLowerCase();
    if (!next.contains('@') || next.length < 5) {
      throw const ServerFailure('Enter a valid email address.');
    }
    final current = _client.auth.currentUser?.email?.toLowerCase();
    if (current != null && current == next) {
      throw const ServerFailure('That is already your current email.');
    }
    try {
      await _client.auth.updateUser(
        UserAttributes(email: next),
        emailRedirectTo: AppConfig.oauthRedirectUrl,
      );
      AppLog.i('Email change requested → $next');
    } on AuthException catch (e) {
      AppLog.w('Email change failed: ${e.message}');
      throw ServerFailure(e.message);
    }
  }
}
