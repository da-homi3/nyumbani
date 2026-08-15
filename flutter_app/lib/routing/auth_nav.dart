import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// After auth, return to the page that sent the user to login (unlock/save),
/// otherwise land on home.
void navigateAfterAuth(BuildContext context, {String? from}) {
  final dest = (from != null && from.isNotEmpty && from.startsWith('/')) ? from : null;
  if (dest != null && dest != '/login' && dest != '/signup' && dest != '/splash') {
    context.go(dest);
    return;
  }
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go('/home');
}

String loginLocation({String? from}) {
  if (from == null || from.isEmpty || from == '/login' || from == '/signup') {
    return '/login';
  }
  return Uri(path: '/login', queryParameters: {'from': from}).toString();
}
