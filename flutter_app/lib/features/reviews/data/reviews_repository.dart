import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(mobileApiRepositoryProvider));
});

class PropertyReview {
  const PropertyReview({
    required this.id,
    required this.ratingOverall,
    required this.createdAt,
    this.waterReliability,
    this.securityRating,
    this.internetReliability,
    this.cleanliness,
    this.comment,
    this.reviewerName,
  });

  final String id;
  final double ratingOverall;
  final String createdAt;
  final double? waterReliability;
  final double? securityRating;
  final double? internetReliability;
  final double? cleanliness;
  final String? comment;
  final String? reviewerName;

  factory PropertyReview.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    String? name;
    if (profiles is Map) {
      name = profiles['full_name'] as String?;
    }
    name ??= json['reviewerName'] as String? ?? json['reviewer_name'] as String?;

    return PropertyReview(
      id: json['id']?.toString() ?? '',
      ratingOverall: (json['rating_overall'] as num?)?.toDouble() ??
          (json['ratingOverall'] as num?)?.toDouble() ??
          0,
      waterReliability: (json['water_reliability'] as num?)?.toDouble() ??
          (json['waterReliability'] as num?)?.toDouble(),
      securityRating: (json['security_rating'] as num?)?.toDouble() ??
          (json['securityRating'] as num?)?.toDouble(),
      internetReliability: (json['internet_reliability'] as num?)?.toDouble() ??
          (json['internetReliability'] as num?)?.toDouble(),
      cleanliness: (json['cleanliness'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
      reviewerName: name,
      createdAt: (json['created_at'] as String?) ?? (json['createdAt'] as String?) ?? '',
    );
  }
}

class ReviewsRepository {
  ReviewsRepository(this._api);
  final MobileApiRepository _api;

  Future<List<PropertyReview>> forListing(String listingId) async {
    final json = await _api.listingReviews(listingId);
    final raw = json['reviews'] ?? json['items'] ?? json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => PropertyReview.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.id.isNotEmpty)
        .toList();
  }
}

final listingReviewsProvider =
    FutureProvider.autoDispose.family<List<PropertyReview>, String>((ref, listingId) {
  return ref.watch(reviewsRepositoryProvider).forListing(listingId);
});
