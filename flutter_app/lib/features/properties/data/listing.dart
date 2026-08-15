class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.neighborhood,
    required this.rentKes,
    required this.bedrooms,
    required this.bathrooms,
    required this.images,
    required this.isVerified,
    required this.isVacant,
    required this.propertyType,
    this.description,
    this.amenities = const [],
    this.pricingMode,
    this.pricePeriod,
    this.latitude,
    this.longitude,
    this.videoUrl,
    this.tourUrl,
    this.authenticityScore,
  });

  final String id;
  final String title;
  final String neighborhood;
  final int rentKes;
  final int bedrooms;
  final int bathrooms;
  final List<String> images;
  final bool isVerified;
  final bool isVacant;
  final String propertyType;
  final String? description;
  final List<String> amenities;
  final String? pricingMode;
  final String? pricePeriod;
  final double? latitude;
  final double? longitude;
  final String? videoUrl;
  final String? tourUrl;
  final int? authenticityScore;

  String get primaryImage => images.isNotEmpty ? images.first : '';

  String get priceLabel {
    final period = pricePeriod == 'night'
        ? '/ night'
        : pricePeriod == 'week'
            ? '/ week'
            : '/ mo';
    return 'KES ${_formatKes(rentKes)}$period';
  }

  static String _formatKes(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    final amenitiesRaw = json['amenities'];
    return Listing(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?) ?? 'Untitled',
      neighborhood: (json['neighborhood'] as String?) ?? '',
      rentKes: (json['rent_kes'] as num?)?.toInt() ?? 0,
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 0,
      images: imagesRaw is List
          ? imagesRaw.whereType<String>().toList()
          : const [],
      isVerified: json['is_verified'] == true,
      isVacant: json['is_vacant'] != false,
      propertyType: (json['property_type'] as String?) ?? '',
      description: json['description'] as String?,
      amenities: amenitiesRaw is List
          ? amenitiesRaw.whereType<String>().toList()
          : const [],
      pricingMode: json['pricing_mode'] as String?,
      pricePeriod: json['price_period'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      videoUrl: (json['video_url'] as String?) ?? (json['videoUrl'] as String?),
      tourUrl: (json['tour_url'] as String?) ?? (json['tourUrl'] as String?),
      authenticityScore: (json['authenticity_score'] as num?)?.toInt(),
    );
  }
}

class ListingsPage {
  const ListingsPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<Listing> items;
  final int total;
  final int limit;
  final int offset;

  factory ListingsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return ListingsPage(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Listing.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.id.isNotEmpty)
              .toList()
          : const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }
}
