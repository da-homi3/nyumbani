import 'package:flutter_test/flutter_test.dart';

import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';

void main() {
  test('AppConfig exposes mobile BFF v1 path', () {
    expect(AppConfig.mobileApiV1.endsWith('/api/mobile/v1'), isTrue);
    expect(AppConfig.appClient, 'flutter');
  });

  test('NetworkFailure has user-safe message', () {
    const f = NetworkFailure();
    expect(f.message.toLowerCase(), contains('internet'));
  });
}
