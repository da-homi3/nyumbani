import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nyumbasearch/core/analytics/analytics_client.dart';
import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/network/connectivity_provider.dart';
import 'package:nyumbasearch/core/push/push_registration_host.dart';
import 'package:nyumbasearch/core/theme/app_theme.dart';
import 'package:nyumbasearch/core/utils/app_log.dart';
import 'package:nyumbasearch/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await initializeFirebaseMessaging();

  if (AppConfig.hasSupabaseKey) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );
    AppLog.i('Supabase initialized');
  } else {
    AppLog.w(
      'SUPABASE_ANON_KEY missing — pass --dart-define=SUPABASE_ANON_KEY=... '
      '(publishable key only). Auth will be unavailable until configured.',
    );
  }

  runApp(
    ProviderScope(
      child: NyumbaSearchApp(firebaseReady: firebaseReady),
    ),
  );
}

class NyumbaSearchApp extends ConsumerStatefulWidget {
  const NyumbaSearchApp({super.key, this.firebaseReady = false});

  final bool firebaseReady;

  @override
  ConsumerState<NyumbaSearchApp> createState() => _NyumbaSearchAppState();
}

class _NyumbaSearchAppState extends ConsumerState<NyumbaSearchApp> {
  var _trackedOpen = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    if (!_trackedOpen) {
      _trackedOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(analyticsProvider).track(AnalyticsEvents.appOpened);
      });
    }
    return PushRegistrationHost(
      firebaseReady: widget.firebaseReady,
      child: MaterialApp.router(
        title: 'NyumbaSearch',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return OfflineBannerHost(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
