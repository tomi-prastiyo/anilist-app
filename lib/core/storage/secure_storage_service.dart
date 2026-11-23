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

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: keyAccessToken);
  }

  Future<void> clearAccessToken() async {
    await _storage.delete(key: keyAccessToken);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
