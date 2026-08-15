import 'package:flutter_test/flutter_test.dart';

import 'package:nyumbasearch/features/properties/data/listing.dart';

void main() {
  test('Listing.fromJson maps BFF property payload', () {
    final listing = Listing.fromJson({
      'id': '29808f5a-9754-4a17-afa6-f951a6d9d969',
      'title': 'Furnished 1 Bedroom',
      'neighborhood': 'Mombasa Road',
      'rent_kes': 5500,
      'bedrooms': 1,
      'bathrooms': 1,
      'images': ['https://example.com/a.jpg'],
      'is_verified': true,
      'is_vacant': true,
      'property_type': 'bnb',
      'price_period': 'night',
    });

    expect(listing.priceLabel, contains('5,500'));
    expect(listing.primaryImage, startsWith('https://'));
    expect(listing.isVerified, isTrue);
  });
}
