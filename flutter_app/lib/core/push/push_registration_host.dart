import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/navigation/in_app_navigation.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/utils/app_log.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/app_router.dart';

/// Background isolate handler (must be top-level; register before [runApp]).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inbox is fetched via BFF when the app opens.
}

/// Call from [main] before [runApp]. Returns true when Firebase is usable.
Future<bool> initializeFirebaseMessaging() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLog.i('Firebase Messaging ready');
    return true;
  } catch (e, st) {
    AppLog.w(
      'Firebase Messaging skipped (need android/app/google-services.json). $e',
    );
    AppLog.e('Firebase init failed', e, st);
    return false;
  }
}

/// Registers FCM token with Mobile BFF when the user is signed in.
class PushRegistrationHost extends ConsumerStatefulWidget {
  const PushRegistrationHost({
    super.key,
    required this.child,
    required this.firebaseReady,
  });

  final Widget child;
  final bool firebaseReady;

  @override
  ConsumerState<PushRegistrationHost> createState() =>
      _PushRegistrationHostState();
}

class _PushRegistrationHostState extends ConsumerState<PushRegistrationHost> {
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  String? _lastRegisteredToken;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseReady) {
      _tokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        unawaited(_registerToken(token));
      });
      _openedAppSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
      unawaited(_syncTokenIfSignedIn());
      unawaited(_handleColdStartNotification());
    }
  }

  @override
  void dispose() {
    unawaited(_tokenRefreshSub?.cancel() ?? Future<void>.value());
    unawaited(_openedAppSub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _handleColdStartNotification() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      await _navigateFromPush(message);
    }
  }

  void _onNotificationOpened(RemoteMessage message) {
    unawaited(_navigateFromPush(message));
  }

  Future<void> _navigateFromPush(RemoteMessage message) async {
    final href = message.data['href']?.trim();
    if (href == null || href.isEmpty || href == '/') return;

    await ref.read(authControllerProvider.notifier).waitForHydration();
    if (!mounted) return;

    final router = ref.read(goRouterProvider);
    AppLog.i('FCM open href=$href');
    await InAppNavigation.openHref(router, href);
  }

  Future<void> _syncTokenIfSignedIn() async {
    if (!widget.firebaseReady) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (e, st) {
      AppLog.e('FCM getToken failed', e, st);
    }
  }

  Future<void> _registerToken(String token) async {
    if (_lastRegisteredToken == token) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    try {
      await ref.read(mobileApiRepositoryProvider).registerFcmToken(token);
      _lastRegisteredToken = token;
      AppLog.i('FCM token registered with BFF');
    } catch (e, st) {
      AppLog.e('FCM token register failed', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (prev, next) {
      final session = next.valueOrNull;
      if (session != null) {
        unawaited(_syncTokenIfSignedIn());
      } else {
        _lastRegisteredToken = null;
      }
    });
    return widget.child;
  }
}
