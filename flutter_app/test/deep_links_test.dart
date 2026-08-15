import 'package:flutter_test/flutter_test.dart';

import 'package:nyumbasearch/routing/deep_links.dart';

void main() {
  test('maps tenant property App Links to in-app detail', () {
    expect(
      DeepLinks.toAppLocation(
        Uri.parse('https://nyumbasearch.com/tenant/property/abc-123'),
      ),
      '/property/abc-123',
    );
    expect(
      DeepLinks.toAppLocation(
        Uri.parse('https://www.nyumbasearch.com/tenant/property/abc-123'),
      ),
      '/property/abc-123',
    );
  });

  test('maps short property path and tenant home', () {
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/property/xyz')),
      '/property/xyz',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/tenant')),
      '/home',
    );
  });

  test('maps tenancy invite App Links', () {
    expect(
      DeepLinks.toAppLocation(
        Uri.parse('https://nyumbasearch.com/tenant/invite/11111111-1111-1111-1111-111111111111'),
      ),
      '/tenant/invite/11111111-1111-1111-1111-111111111111',
    );
  });

  test('maps caretaker and landlord plan/boost deep links', () {
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/caretaker')),
      '/caretaker/login',
    );
    expect(
      DeepLinks.toAppLocation(
        Uri.parse('https://nyumbasearch.com/caretaker/dashboard'),
      ),
      '/caretaker/dashboard',
    );
    expect(
      DeepLinks.toAppLocation(
        Uri.parse('https://nyumbasearch.com/landlord/boost?propertyId=abc'),
      ),
      '/landlord/boost?propertyId=abc',
    );
    expect(
      DeepLinks.toAppLocation(
        Uri.parse('https://nyumbasearch.com/landlord/checkout?plan=pro'),
      ),
      '/landlord/plan',
    );
  });

  test('maps agency / manager / services / tenant tools', () {
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/agency')),
      '/agency',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/agency/team')),
      '/agency/team',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/manager')),
      '/manager',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/services')),
      '/services',
    );
    expect(
      DeepLinks.toAppLocation(
        Uri.parse('https://nyumbasearch.com/services/provider/abc'),
      ),
      '/services/abc',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/tenant/rent')),
      '/rent',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/plus')),
      '/plus',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/admin')),
      '/admin',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/landlord/leads')),
      '/landlord/leads',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/saved-searches')),
      '/saved-searches',
    );
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/pm')),
      '/pm',
    );
  });

  test('ignores unknown website paths', () {
    expect(
      DeepLinks.toAppLocation(Uri.parse('https://nyumbasearch.com/about')),
      isNull,
    );
  });

  test('portalUriForRole builds website URLs', () {
    expect(
      DeepLinks.portalUriForRole('landlord')?.toString(),
      'https://nyumbasearch.com/landlord',
    );
    expect(DeepLinks.portalUriForRole('tenant'), isNull);
  });
}
