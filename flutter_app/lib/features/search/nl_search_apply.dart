import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/properties/data/listings_providers.dart';

class NlSearchResult {
  const NlSearchResult({
    required this.remainingQuery,
    required this.hints,
    this.neighborhood,
    this.propertyType,
    this.maxRent,
    this.pricingMode,
    this.verifiedOnly = false,
  });

  final String remainingQuery;
  final List<String> hints;
  final String? neighborhood;
  final String? propertyType;
  final int? maxRent;
  final String? pricingMode;
  final bool verifiedOnly;
}

/// Pure parser for mobile BFF `/search/nl` JSON (testable without network).
NlSearchResult? parseNlSearchResponse(
  Map<String, dynamic> json, {
  required String fallbackQuery,
}) {
  final filters = json['filters'];
  final hintsRaw = json['hints'];
  final hints =
      hintsRaw is List ? hintsRaw.map((h) => h.toString()).toList() : const <String>[];
  if (filters is! Map) {
    return NlSearchResult(remainingQuery: fallbackQuery, hints: hints);
  }

  final maxRent = filters['maxRent'];
  final pricingMode = filters['pricingMode'] as String?;

  return NlSearchResult(
    remainingQuery: (json['remainingQuery'] as String?) ?? fallbackQuery,
    hints: hints,
    neighborhood: filters['neighborhood'] as String?,
    propertyType: filters['propertyType'] as String?,
    maxRent: maxRent is num ? maxRent.toInt() : null,
    pricingMode: pricingMode == 'rent' || pricingMode == 'sale' ? pricingMode : null,
    verifiedOnly: filters['verifiedOnly'] == true,
  );
}

Future<NlSearchResult?> fetchNlSearch(WidgetRef ref, String raw) async {
  final trimmed = raw.trim();
  if (trimmed.length < 6) return null;

  try {
    final json = await ref.read(mobileApiRepositoryProvider).parseNlSearch(trimmed);
    return parseNlSearchResponse(json, fallbackQuery: trimmed);
  } catch (_) {
    return null;
  }
}

void applyNlSearchToFilters(WidgetRef ref, NlSearchResult parsed) {
  ref.read(searchFiltersProvider.notifier).update(
        (f) => f.copyWith(
          q: parsed.remainingQuery,
          neighborhood: parsed.neighborhood,
          type: parsed.propertyType,
          maxRent: parsed.maxRent ?? f.maxRent,
          pricingMode: parsed.pricingMode ?? f.pricingMode,
          verifiedOnly: parsed.verifiedOnly || f.verifiedOnly,
          clearNeighborhood: parsed.neighborhood == null,
          clearType: parsed.propertyType == null,
          clearMaxRent: parsed.maxRent == null,
          clearPricingMode: parsed.pricingMode == null,
        ),
      );
}
