import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CaretakerSessionStore {
  CaretakerSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'caretaker_session_token';
  static const _nameKey = 'caretaker_session_name';

  final FlutterSecureStorage _storage;

  Future<void> save({required String token, String? name}) async {
    await _storage.write(key: _tokenKey, value: token);
    if (name != null && name.trim().isNotEmpty) {
      await _storage.write(key: _nameKey, value: name.trim());
    }
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readName() => _storage.read(key: _nameKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _nameKey);
  }
}

final caretakerSessionStore = CaretakerSessionStore();
