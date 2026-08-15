import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

/// Fade + slight Y — mirrors web `PageTransition` / MOTION_EASE.
CustomTransitionPage<void> nyumbaFadeSlidePage({
  required LocalKey key,
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<void>(
    key: key,
    name: name,
    child: child,
    transitionDuration: NyumbaTokens.durationMedium,
    reverseTransitionDuration: NyumbaTokens.durationFast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: NyumbaTokens.easeOutSoft,
        reverseCurve: NyumbaTokens.easeSmooth,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// GoRoute with web-like entrance; use for push/go screens (not shell tabs).
GoRoute fadeRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  List<RouteBase> routes = const [],
  GoRouterRedirect? redirect,
}) {
  return GoRoute(
    path: path,
    redirect: redirect,
    routes: routes,
    pageBuilder: (context, state) => nyumbaFadeSlidePage(
      key: state.pageKey,
      name: state.name ?? state.uri.toString(),
      child: builder(context, state),
    ),
  );
}
