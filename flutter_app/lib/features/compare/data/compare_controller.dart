import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'nyumba_compare_ids_v1';
const _maxCompare = 4;

class CompareIdsNotifier extends StateNotifier<List<String>> {
  CompareIdsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_prefsKey) ?? const [];
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state);
  }

  /// Returns false if list is full and id was not already present.
  Future<bool> toggle(String id) async {
    if (state.contains(id)) {
      state = state.where((e) => e != id).toList();
      await _persist();
      return true;
    }
    if (state.length >= _maxCompare) return false;
    state = [...state, id];
    await _persist();
    return true;
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }
}

final compareIdsProvider =
    StateNotifierProvider<CompareIdsNotifier, List<String>>((ref) {
  return CompareIdsNotifier();
});
