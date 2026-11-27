import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String keyAccessToken = 'anilist_access_token';

  String? _cachedToken;
  bool _hasLoadedToken = false;

  Future<void> saveAccessToken(String token) async {
    _cachedToken = token;
    _hasLoadedToken = true;
    await _storage.write(key: keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    if (_hasLoadedToken) return _cachedToken;
    _cachedToken = await _storage.read(key: keyAccessToken);
    _hasLoadedToken = true;
    return _cachedToken;
  }

  Future<void> clearAccessToken() async {
    _cachedToken = null;
    _hasLoadedToken = true;
    await _storage.delete(key: keyAccessToken);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
