// Live smoke against production Mobile BFF.
// Usage: dart run tool/live_bff_smoke.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://nyumbasearch.com/api/mobile/v1',
      headers: {'X-App-Client': 'flutter', 'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (_) => true,
    ),
  );

  var failed = 0;

  Future<void> check(
    String name,
    String path, {
    int expectStatus = 200,
    String method = 'GET',
  }) async {
    stdout.writeln('→ $name ($method $path) expect=$expectStatus');
    try {
      final Response res;
      if (method == 'POST') {
        res = await dio.post(path, data: {});
      } else if (method == 'PATCH') {
        res = await dio.patch(path, data: {});
      } else if (method == 'PUT') {
        res = await dio.put(path, data: {});
      } else if (method == 'DELETE') {
        res = await dio.delete(path);
      } else {
        res = await dio.get(path);
      }
      final ok = res.statusCode == expectStatus;
      stdout.writeln('  status=${res.statusCode} ok=$ok');
      if (!ok) {
        failed++;
        stdout.writeln('  body=${res.data}');
        return;
      }
      if (expectStatus == 200 && res.data is Map) {
        final map = Map<String, dynamic>.from(res.data as Map);
        if (path.endsWith('/health') && map['status'] != 'ok') {
          failed++;
          stdout.writeln('  unexpected health: ${jsonEncode(map)}');
        }
        if (path.contains('/listings') && map['items'] is! List) {
          failed++;
          stdout.writeln('  listings missing items');
        } else if (path.contains('/listings') && !path.contains('/reviews')) {
          final total = map['total'];
          final n = (map['items'] as List).length;
          stdout.writeln('  items=$n total=$total');
        }
      }
    } catch (e) {
      failed++;
      stdout.writeln('  ERROR $e');
    }
  }

  await check('BFF health', '/health');
  await check('BFF listings', '/listings?limit=1');
  await check('subscriptions catalog', '/subscriptions/catalog');
  await check('providers', '/providers?limit=1');

  // Auth-gated: unauthenticated must be 401 (proves route is live).
  await check('messages auth', '/messages', expectStatus: 401);
  await check('messages create auth', '/messages', method: 'POST', expectStatus: 401);
  await check('subscriptions current auth', '/subscriptions/current', expectStatus: 401);
  await check('notification prefs auth', '/notifications/prefs', expectStatus: 401);
  await check('payments auth', '/payments', expectStatus: 401);
  await check('landlord dashboard auth', '/landlords/dashboard', expectStatus: 401);
  await check('portal status auth', '/me/portal-status', expectStatus: 401);
  await check(
    'invite preview public',
    '/tenants/invites/550e8400-e29b-41d4-a716-446655440000',
    expectStatus: 200,
  );
  await check('notifications auth', '/notifications', expectStatus: 401);
  await check('properties auth', '/properties', expectStatus: 401);
  await check('pm properties auth', '/property-management/properties', expectStatus: 401);
  await check(
    'pm create auth',
    '/property-management/properties',
    method: 'POST',
    expectStatus: 401,
  );
  await check(
    'pm module subscribe auth',
    '/subscriptions/pm-module',
    method: 'POST',
    expectStatus: 401,
  );
  await check('caretaker dashboard auth', '/caretakers/dashboard', expectStatus: 401);
  await check(
    'otp request public',
    '/auth/otp/request',
    method: 'POST',
    expectStatus: 400,
  );
  await check('tenant maintenance auth', '/tenants/maintenance', expectStatus: 401);
  await check('tenant complaints auth', '/tenants/complaints', expectStatus: 401);
  await check(
    'verification create auth',
    '/verification/requests',
    method: 'POST',
    expectStatus: 401,
  );
  await check(
    'admin verification queue auth',
    '/admin/verification-requests',
    expectStatus: 401,
  );
  await check(
    'admin identity verifications auth',
    '/admin/verifications',
    expectStatus: 401,
  );
  await check(
    'subscriptions checkout auth',
    '/subscriptions/checkout',
    method: 'POST',
    expectStatus: 401,
  );
  await check('caretakers list auth', '/caretakers', expectStatus: 401);
  await check('payouts auth', '/landlords/payouts', expectStatus: 401);
  await check(
    'admin portal applications auth',
    '/admin/portal-applications',
    expectStatus: 401,
  );
  await check(
    'admin pending providers auth',
    '/admin/service-providers',
    expectStatus: 401,
  );
  await check('admin scam reports auth', '/admin/scam-reports', expectStatus: 401);
  await check(
    'rent sms claim auth',
    '/tenants/rent/sms-claim',
    method: 'POST',
    expectStatus: 401,
  );
  await check('provider categories', '/providers/categories');
  await check('provider me auth', '/providers/me', expectStatus: 401);
  await check(
    'provider register auth',
    '/providers',
    method: 'POST',
    expectStatus: 401,
  );
  await check('admin properties auth', '/admin/properties', expectStatus: 401);
  await check(
    'pm complaints auth',
    '/property-management/properties/550e8400-e29b-41d4-a716-446655440000/complaints',
    expectStatus: 401,
  );
  await check(
    'pm staff auth',
    '/property-management/properties/550e8400-e29b-41d4-a716-446655440000/staff',
    expectStatus: 401,
  );
  await check(
    'password reset request',
    '/auth/password-reset/request',
    method: 'POST',
    expectStatus: 400,
  );
  await check('org membership auth', '/me/org-membership', expectStatus: 401);
  await check('org team auth', '/org/team', expectStatus: 401);
  await check('agency dashboard auth', '/agencies/dashboard', expectStatus: 401);
  await check('manager dashboard auth', '/managers/dashboard', expectStatus: 401);
  await check('referrals me auth', '/referrals/me', expectStatus: 401);
  await check('admin pm overview auth', '/admin/pm/overview', expectStatus: 401);
  await check('landlord analytics auth', '/landlords/analytics', expectStatus: 401);
  await check('saved searches auth', '/saved-searches', expectStatus: 401);
  await check(
    'compare listings',
    '/listings/compare',
    method: 'POST',
    expectStatus: 400,
  );
  await check(
    'pm maintenance status auth',
    '/property-management/maintenance/550e8400-e29b-41d4-a716-446655440000',
    method: 'PATCH',
    expectStatus: 401,
  );
  await check(
    'tenant maintenance confirm auth',
    '/tenants/maintenance/550e8400-e29b-41d4-a716-446655440000/confirm',
    method: 'POST',
    expectStatus: 401,
  );
  await check(
    'review eligibility auth',
    '/listings/550e8400-e29b-41d4-a716-446655440000/reviews/eligibility',
    expectStatus: 401,
  );
  await check(
    'payments initiate auth',
    '/payments/initiate',
    method: 'POST',
    expectStatus: 401,
  );
  await check(
    'admin authenticity auth',
    '/admin/properties/550e8400-e29b-41d4-a716-446655440000/authenticity',
    method: 'PATCH',
    expectStatus: 401,
  );
  await check(
    'pm dashboard auth',
    '/property-management/properties/550e8400-e29b-41d4-a716-446655440000/dashboard',
    expectStatus: 401,
  );
  await check(
    'pm unit update auth',
    '/property-management/units/550e8400-e29b-41d4-a716-446655440000',
    method: 'PATCH',
    expectStatus: 401,
  );
  await check(
    'pm rent generate auth',
    '/property-management/properties/550e8400-e29b-41d4-a716-446655440000/rent/generate',
    method: 'POST',
    expectStatus: 401,
  );

  try {
    final site = await Dio().get(
      'https://nyumbasearch.com/api/health',
      options: Options(validateStatus: (_) => true),
    );
    stdout.writeln('→ site /api/health status=${site.statusCode}');
    if (site.statusCode != 200) failed++;
  } catch (e) {
    failed++;
    stdout.writeln('→ site /api/health ERROR $e');
  }

  Future<void> checkWellKnown(String name, String url, {required bool Function(dynamic data) ok}) async {
    stdout.writeln('→ $name ($url)');
    try {
      final res = await Dio().get(url, options: Options(validateStatus: (_) => true));
      stdout.writeln('  status=${res.statusCode}');
      if (res.statusCode != 200 || !ok(res.data)) {
        failed++;
        stdout.writeln('  body=${res.data}');
      }
    } catch (e) {
      failed++;
      stdout.writeln('  ERROR $e');
    }
  }

  await checkWellKnown(
    'AASA',
    'https://nyumbasearch.com/.well-known/apple-app-site-association',
    ok: (data) {
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : (data is String ? jsonDecode(data) as Map<String, dynamic> : null);
      if (map == null) return false;
      final details = (((map['applinks'] as Map?)?['details']) as List?) ?? const [];
      if (details.isEmpty) return false;
      final appID = (details.first as Map)['appID']?.toString() ?? '';
      return appID.endsWith('.ke.co.nyumbasearch.app');
    },
  );
  await checkWellKnown(
    'assetlinks',
    'https://nyumbasearch.com/.well-known/assetlinks.json',
    ok: (data) {
      final list = data is List
          ? data
          : (data is String ? jsonDecode(data) as List : null);
      if (list == null || list.isEmpty) return false;
      final target = (list.first as Map)['target'] as Map?;
      return target?['package_name'] == 'ke.co.nyumbasearch.app';
    },
  );

  if (failed > 0) {
    stderr.writeln('SMOKE FAILED ($failed check(s))');
    exit(1);
  }
  stdout.writeln('SMOKE OK');
}
