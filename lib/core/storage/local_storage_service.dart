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
  static const String keyYuyuyuHeroine = 'key_yuyuyu_heroine';
  static const String keyIsGuest = 'key_is_guest';
  static const String keyTitleLanguage = 'key_title_language';
  static const String keyScoreFormat = 'key_score_format';
  static const String keyViewerId = 'key_viewer_id';
  static const String keyRecentSearches = 'key_recent_searches';
  static const String keyReadNotificationIds = 'key_read_notification_ids';
  static const String keyForcedUnreadNotificationIds = 'key_forced_unread_notification_ids';
  static const String keyLastNotificationIds = 'key_last_notification_ids';

  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  List<String> getRecentSearches() => _prefs.getStringList(keyRecentSearches) ?? [];

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = getRecentSearches();
    current.remove(trimmed);
    current.insert(0, trimmed);
    if (current.length > 10) current.removeLast();
    await _prefs.setStringList(keyRecentSearches, current);
  }

  Future<void> removeRecentSearch(String query) async {
    final current = getRecentSearches();
    current.remove(query);
    await _prefs.setStringList(keyRecentSearches, current);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(keyRecentSearches);
  }

  Future<bool> remove(String key) => _prefs.remove(key);

  Set<int> getIntIdSet(String key) {
    final raw = _prefs.getStringList(key) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> setIntIdSet(String key, Set<int> ids, {int maxEntries = 200}) async {
    final list = ids.toList();
    if (list.length > maxEntries) {
      list.removeRange(0, list.length - maxEntries);
    }
    await _prefs.setStringList(key, list.map((e) => e.toString()).toList());
  }

  List<int> getIntIdList(String key) {
    final raw = _prefs.getStringList(key) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toList();
  }

  Future<void> setIntIdList(String key, List<int> ids, {int maxEntries = 50}) async {
    final list = ids.length > maxEntries ? ids.sublist(0, maxEntries) : ids;
    await _prefs.setStringList(key, list.map((e) => e.toString()).toList());
  }

  bool get isGuest => getBool(keyIsGuest, defaultValue: false);
  set isGuest(bool val) => setBool(keyIsGuest, val);

  String get titleLanguage => getString(keyTitleLanguage) ?? 'ROMAJI';
  set titleLanguage(String val) => setString(keyTitleLanguage, val);

  String get scoreFormat => getString(keyScoreFormat) ?? 'POINT_100';
  set scoreFormat(String val) => setString(keyScoreFormat, val);
}
