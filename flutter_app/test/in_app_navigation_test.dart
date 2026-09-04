import 'package:flutter_test/flutter_test.dart';

import 'package:nyumbasearch/core/navigation/in_app_navigation.dart';

void main() {
  group('InAppNavigation.resolveHref', () {
    test('maps absolute tenant property URLs', () {
      expect(
        InAppNavigation.resolveHref(
          'https://nyumbasearch.com/tenant/property/abc-123',
        ),
        '/property/abc-123',
      );
    });

    test('maps relative paths', () {
      expect(InAppNavigation.resolveHref('/messages/thread-1'), '/messages/thread-1');
      expect(InAppNavigation.resolveHref('/rent'), '/rent');
    });

    test('maps tenant workflow notification hrefs', () {
      expect(InAppNavigation.resolveHref('/tenant/applications'), '/applications');
      expect(InAppNavigation.resolveHref('/tenant/viewings'), '/viewings');
      expect(InAppNavigation.resolveHref('/landlord/applications'), '/landlord/applications');
      expect(InAppNavigation.resolveHref('/landlord/viewings'), '/landlord/viewings');
      expect(InAppNavigation.resolveHref('/viewings'), '/viewings');
    });

    test('returns null for empty or root href', () {
      expect(InAppNavigation.resolveHref(''), isNull);
      expect(InAppNavigation.resolveHref('/'), isNull);
    });

    test('maps FCM default data href from push payload', () {
      expect(
        InAppNavigation.resolveHref(
          'https://nyumbasearch.com/tenant/property/push-listing-id',
        ),
        '/property/push-listing-id',
      );
    });
  });
}
