import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';

class FeaturedAgency {
  const FeaturedAgency({
    required this.id,
    required this.name,
    required this.listingCount,
    this.logoUrl,
    this.slug,
  });

  final String id;
  final String name;
  final int listingCount;
  final String? logoUrl;
  final String? slug;

  factory FeaturedAgency.fromJson(Map<String, dynamic> json) {
    return FeaturedAgency(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Provider',
      listingCount: (json['listingCount'] as num?)?.toInt() ??
          (json['listing_count'] as num?)?.toInt() ??
          0,
      logoUrl: json['logoUrl']?.toString() ?? json['logo_url']?.toString(),
      slug: json['slug']?.toString(),
    );
  }
}

final featuredAgenciesProvider = FutureProvider.autoDispose<List<FeaturedAgency>>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).featuredAgencies();
  final raw = json['agencies'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((row) => FeaturedAgency.fromJson(Map<String, dynamic>.from(row)))
      .where((a) => a.id.isNotEmpty)
      .toList();
});
