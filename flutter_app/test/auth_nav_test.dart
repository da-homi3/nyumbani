import 'package:flutter_test/flutter_test.dart';

import 'package:nyumbasearch/features/properties/presentation/contact_unlock_card.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

void main() {
  test('isKenyanMpesaPhone accepts common formats', () {
    expect(isKenyanMpesaPhone('0712345678'), isTrue);
    expect(isKenyanMpesaPhone('254712345678'), isTrue);
    expect(isKenyanMpesaPhone('712345678'), isTrue);
    expect(isKenyanMpesaPhone('123'), isFalse);
    expect(isKenyanMpesaPhone(''), isFalse);
  });

  test('loginLocation preserves from query', () {
    expect(loginLocation(), '/login');
    expect(loginLocation(from: '/property/abc'), '/login?from=%2Fproperty%2Fabc');
  });
}
