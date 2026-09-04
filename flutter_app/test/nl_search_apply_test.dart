import 'package:flutter_test/flutter_test.dart';

import 'package:nyumbasearch/features/search/nl_search_apply.dart';

void main() {
  test('parseNlSearchResponse maps BFF filters', () {
    final parsed = parseNlSearchResponse(
      {
        'filters': {
          'neighborhood': 'Kilimani',
          'propertyType': 'two_bedroom',
          'maxRent': 60000,
          'pricingMode': 'rent',
          'verifiedOnly': false,
        },
        'remainingQuery': '',
        'hints': ['2 bedroom', 'Under KES 60,000', 'Kilimani'],
      },
      fallbackQuery: '2 bedroom in Kilimani under 60k',
    );

    expect(parsed, isNotNull);
    expect(parsed!.neighborhood, 'Kilimani');
    expect(parsed.propertyType, 'two_bedroom');
    expect(parsed.maxRent, 60000);
    expect(parsed.pricingMode, 'rent');
    expect(parsed.hints, contains('Kilimani'));
  });

  test('parseNlSearchResponse returns hints-only when filters missing', () {
    final parsed = parseNlSearchResponse(
      {'hints': ['For rent']},
      fallbackQuery: 'homes for rent',
    );

    expect(parsed?.remainingQuery, 'homes for rent');
    expect(parsed?.hints, ['For rent']);
    expect(parsed?.neighborhood, isNull);
  });
}
