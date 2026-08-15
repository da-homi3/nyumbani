import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/properties/data/listing.dart';

final mapboxTokenProvider = FutureProvider<String?>((ref) async {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  final res = await dio.get<Map<String, dynamic>>('/api/mapbox-token');
  final token = res.data?['token'];
  if (token is String && token.startsWith('pk.')) return token;
  return null;
});

final mapListingsProvider = FutureProvider<ListingsPage>((ref) async {
  final repo = ref.watch(mobileApiRepositoryProvider);
  // Pull a larger pool for markers; only items with coordinates are plotted.
  return repo.searchListings(limit: 100, sortBy: 'newest').then(ListingsPage.fromJson);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(mobileApiRepositoryProvider));
});

class FavoritesRepository {
  FavoritesRepository(this._api);
  final MobileApiRepository _api;

  Future<List<Listing>> list() async {
    final json = await _api.listSaved();
    final raw = json['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Listing.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<bool> save(String propertyId) async {
    final json = await _api.saveProperty(propertyId);
    return json['saved'] == true;
  }

  Future<bool> unsave(String propertyId) async {
    final json = await _api.unsaveProperty(propertyId);
    return json['saved'] == false;
  }
}

final savedListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  return ref.watch(favoritesRepositoryProvider).list();
});

/// Local optimistic set of saved IDs for the current session (synced on load).
final savedIdsProvider =
    StateNotifierProvider<SavedIdsNotifier, AsyncValue<Set<String>>>((ref) {
  return SavedIdsNotifier(ref);
});

class SavedIdsNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  SavedIdsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _authSub = _ref.listen(authSessionProvider, (prev, next) {
      final session = next.valueOrNull;
      if (session == null) {
        state = const AsyncValue.data(<String>{});
      } else if (prev?.valueOrNull?.user.id != session.user.id) {
        refresh();
      }
    });
    final session = _ref.read(authSessionProvider).valueOrNull;
    if (session != null) {
      refresh();
    } else {
      state = const AsyncValue.data(<String>{});
    }
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<Session?>> _authSub;

  @override
  void dispose() {
    _authSub.close();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final session = _ref.read(authSessionProvider).valueOrNull;
      if (session == null) {
        state = const AsyncValue.data(<String>{});
        return;
      }
      final items = await _ref.read(favoritesRepositoryProvider).list();
      state = AsyncValue.data(items.map((e) => e.id).toSet());
    } catch (_) {
      state = AsyncValue.data(<String>{});
    }
  }

  void clear() {
    state = const AsyncValue.data(<String>{});
  }

  bool isSaved(String id) => state.valueOrNull?.contains(id) ?? false;

  Future<void> toggle(String propertyId) async {
    final current = {...(state.valueOrNull ?? <String>{})};
    final wasSaved = current.contains(propertyId);
    if (wasSaved) {
      current.remove(propertyId);
    } else {
      current.add(propertyId);
    }
    state = AsyncValue.data(current);

    try {
      if (wasSaved) {
        await _ref.read(favoritesRepositoryProvider).unsave(propertyId);
      } else {
        await _ref.read(favoritesRepositoryProvider).save(propertyId);
      }
      _ref.invalidate(savedListingsProvider);
    } catch (e) {
      if (wasSaved) {
        current.add(propertyId);
      } else {
        current.remove(propertyId);
      }
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}
