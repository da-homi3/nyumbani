import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/data/listing.dart';
import 'package:nyumbasearch/features/properties/data/listing_intel.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(mobileApiRepositoryProvider));
});

class ListingsRepository {
  ListingsRepository(this._api);
  final MobileApiRepository _api;

  Future<ListingsPage> search({
    String? q,
    String? neighborhood,
    String? locationId,
    String? type,
    String? pricingMode,
    int? minRent,
    int? maxRent,
    int? minBedrooms,
    bool verifiedOnly = false,
    bool parking = false,
    bool petFriendly = false,
    String sortBy = 'newest',
    int limit = 20,
    int offset = 0,
    int? maxImages,
  }) async {
    final json = await _api.searchListings(
      q: q,
      neighborhood: neighborhood,
      locationId: locationId,
      type: type,
      pricingMode: pricingMode,
      minRent: minRent,
      maxRent: maxRent,
      minBedrooms: minBedrooms,
      verifiedOnly: verifiedOnly,
      parking: parking,
      petFriendly: petFriendly,
      sortBy: sortBy,
      limit: limit,
      offset: offset,
      maxImages: maxImages,
    );
    return ListingsPage.fromJson(json);
  }

  Future<Listing> detail(String id) async {
    final json = await _api.listingDetail(id);
    final listing = json['listing'];
    if (listing is! Map) {
      throw StateError('Listing not found');
    }
    return Listing.fromJson(Map<String, dynamic>.from(listing));
  }
}

class SearchFilters {
  const SearchFilters({
    this.q = '',
    this.neighborhood,
    this.locationId,
    this.type,
    this.pricingMode,
    this.minRent,
    this.maxRent,
    this.minBedrooms,
    this.verifiedOnly = false,
    this.sortBy = 'newest',
    this.requireParking = false,
    this.requirePetFriendly = false,
    this.requireWater = false,
    this.requireSecurity = false,
  });

  final String q;
  final String? neighborhood;
  final String? locationId;
  final String? type;
  final String? pricingMode;
  final int? minRent;
  final int? maxRent;
  final int? minBedrooms;
  final bool verifiedOnly;
  final String sortBy;
  final bool requireParking;
  final bool requirePetFriendly;
  final bool requireWater;
  final bool requireSecurity;

  SearchFilters copyWith({
    String? q,
    String? neighborhood,
    String? locationId,
    String? type,
    String? pricingMode,
    int? minRent,
    int? maxRent,
    int? minBedrooms,
    bool? verifiedOnly,
    String? sortBy,
    bool? requireParking,
    bool? requirePetFriendly,
    bool? requireWater,
    bool? requireSecurity,
    bool clearNeighborhood = false,
    bool clearLocationId = false,
    bool clearType = false,
    bool clearPricingMode = false,
    bool clearMinRent = false,
    bool clearMaxRent = false,
    bool clearMinBedrooms = false,
  }) {
    return SearchFilters(
      q: q ?? this.q,
      neighborhood: clearNeighborhood ? null : (neighborhood ?? this.neighborhood),
      locationId: clearLocationId ? null : (locationId ?? this.locationId),
      type: clearType ? null : (type ?? this.type),
      pricingMode: clearPricingMode ? null : (pricingMode ?? this.pricingMode),
      minRent: clearMinRent ? null : (minRent ?? this.minRent),
      maxRent: clearMaxRent ? null : (maxRent ?? this.maxRent),
      minBedrooms: clearMinBedrooms ? null : (minBedrooms ?? this.minBedrooms),
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      sortBy: sortBy ?? this.sortBy,
      requireParking: requireParking ?? this.requireParking,
      requirePetFriendly: requirePetFriendly ?? this.requirePetFriendly,
      requireWater: requireWater ?? this.requireWater,
      requireSecurity: requireSecurity ?? this.requireSecurity,
    );
  }
}

final searchFiltersProvider =
    StateProvider<SearchFilters>((ref) => const SearchFilters());

final homeListingsProvider = FutureProvider<ListingsPage>((ref) async {
  final repo = ref.watch(listingsRepositoryProvider);
  Object? lastError;
  // Featured strip only needs a handful of cards; smaller payloads survive slow
  // emulator networks and cold BFF cache better than limit=12.
  const attempts = <({int limit, int maxImages})>[
    (limit: 6, maxImages: 1),
    (limit: 6, maxImages: 1),
    (limit: 3, maxImages: 1),
  ];
  for (var i = 0; i < attempts.length; i++) {
    final cfg = attempts[i];
    try {
      return await repo.search(
        limit: cfg.limit,
        sortBy: 'newest',
        maxImages: cfg.maxImages,
      );
    } catch (e) {
      lastError = e;
      await Future<void>.delayed(Duration(milliseconds: 600 * (i + 1)));
    }
  }
  Error.throwWithStackTrace(lastError!, StackTrace.current);
});

final searchListingsProvider = FutureProvider.autoDispose<ListingsPage>((ref) async {
  final filters = ref.watch(searchFiltersProvider);
  final repo = ref.watch(listingsRepositoryProvider);
  final page = await repo.search(
    q: filters.q.isEmpty ? null : filters.q,
    neighborhood: filters.neighborhood,
    locationId: filters.locationId,
    type: filters.type,
    pricingMode: filters.pricingMode,
    maxRent: filters.maxRent,
    minRent: filters.minRent,
    minBedrooms: filters.minBedrooms,
    verifiedOnly: filters.verifiedOnly,
    parking: filters.requireParking,
    petFriendly: filters.requirePetFriendly,
    sortBy: filters.sortBy,
    limit: 40,
  );

  // Water/security intel is derived client-side (not a BFF amenity contains filter yet).
  if (!filters.requireWater && !filters.requireSecurity) {
    return page;
  }

  bool matches(Listing listing) {
    final intel = ListingIntel.fromAmenities(listing.amenities);
    if (filters.requireWater) {
      final w = intel.water.toLowerCase();
      if (w.contains('none') || w.contains('unknown') || w.isEmpty) return false;
    }
    if (filters.requireSecurity) {
      final s = intel.security.toLowerCase();
      if (s.contains('none') || s.contains('unknown') || s.isEmpty) return false;
    }
    return true;
  }

  final filtered = page.items.where(matches).toList();
  return ListingsPage(items: filtered, total: filtered.length, limit: page.limit, offset: page.offset);
});

final listingDetailProvider =
    FutureProvider.autoDispose.family<Listing, String>((ref, id) async {
  return ref.watch(listingsRepositoryProvider).detail(id);
});

final recommendationFeedProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;
  final api = ref.watch(mobileApiRepositoryProvider);
  try {
    return await api.recommendationFeed();
  } catch (_) {
    return null;
  }
});
