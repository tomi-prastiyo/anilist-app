import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/yuyuyu_assets.dart';
import '../storage/local_storage_service.dart';
import 'app_theme.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ThemeModeNotifier(storage);
});

final yuyuyuHeroineProvider =
    StateNotifierProvider<YuYuYuHeroineNotifier, YuYuYuHeroine>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return YuYuYuHeroineNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  final LocalStorageService _storage;

  ThemeModeNotifier(this._storage)
      : super(_stringToThemeMode(_storage.getString(LocalStorageService.keyAppTheme)));

  void setThemeMode(AppThemeMode mode) {
    state = mode;
    _storage.setString(LocalStorageService.keyAppTheme, mode.name);
  }

  static AppThemeMode _stringToThemeMode(String? val) {
    if (val == AppThemeMode.system.name) return AppThemeMode.system;
    if (val == AppThemeMode.light.name) return AppThemeMode.light;
    if (val == AppThemeMode.yuyuyu.name) return AppThemeMode.yuyuyu;
    return AppThemeMode.dark;
  }
}

class YuYuYuHeroineNotifier extends StateNotifier<YuYuYuHeroine> {
  final LocalStorageService _storage;

  YuYuYuHeroineNotifier(this._storage)
      : super(YuYuYuAssets.byId(_storage.getString(LocalStorageService.keyYuyuyuHeroine)));

  void setHeroine(YuYuYuHeroine heroine) {
    state = heroine;
    _storage.setString(LocalStorageService.keyYuyuyuHeroine, heroine.id);
  }
}
