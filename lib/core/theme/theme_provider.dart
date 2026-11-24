import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage_service.dart';
import 'app_theme.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  final LocalStorageService _storage;

  ThemeModeNotifier(this._storage)
      : super(_stringToThemeMode(_storage.getString(LocalStorageService.keyAppTheme))) {
    // Initialized from saved preferences
  }

  void setThemeMode(AppThemeMode mode) {
    state = mode;
    _storage.setString(LocalStorageService.keyAppTheme, mode.name);
  }

  static AppThemeMode _stringToThemeMode(String? val) {
    if (val == AppThemeMode.system.name) return AppThemeMode.system;
    if (val == AppThemeMode.light.name) return AppThemeMode.light;
    if (val == AppThemeMode.amoled.name) return AppThemeMode.amoled;
    return AppThemeMode.dark;
  }
}
