import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must override in main ProviderScope');
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static const String keyAppTheme = 'key_app_theme';
  static const String keyIsGuest = 'key_is_guest';
  static const String keyDisplayAdultContent = 'key_display_adult_content';
  static const String keyTitleLanguage = 'key_title_language'; // ROMAJI, ENGLISH, NATIVE
  static const String keyScoreFormat = 'key_score_format'; // POINT_100, POINT_10_DECIMAL, etc.
  static const String keyViewerId = 'key_viewer_id';

  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);

  bool get isGuest => getBool(keyIsGuest, defaultValue: false);
  set isGuest(bool val) => setBool(keyIsGuest, val);

  bool get displayAdultContent => getBool(keyDisplayAdultContent, defaultValue: false);
  set displayAdultContent(bool val) => setBool(keyDisplayAdultContent, val);

  String get titleLanguage => getString(keyTitleLanguage) ?? 'ROMAJI';
  set titleLanguage(String val) => setString(keyTitleLanguage, val);

  String get scoreFormat => getString(keyScoreFormat) ?? 'POINT_100';
  set scoreFormat(String val) => setString(keyScoreFormat, val);
}
