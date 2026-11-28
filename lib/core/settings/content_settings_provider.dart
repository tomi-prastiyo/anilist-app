import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../storage/local_storage_service.dart';

/// Holds the active 18+ adult content display preference, synced with the
/// signed-in AniList user's `options.displayAdultContent` and persisted locally
/// for Guest browsing.
final adultContentProvider = StateNotifierProvider<AdultContentNotifier, bool>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final authController = ref.read(authControllerProvider.notifier);
  final authState = ref.watch(authControllerProvider);

  final initialValue = authState is Authenticated
      ? authState.user.displayAdultContent
      : storage.displayAdultContent;

  return AdultContentNotifier(
    initialValue: initialValue,
    storage: storage,
    authRepo: authRepo,
    authController: authController,
    isAuthenticated: authState is Authenticated,
  );
});

class AdultContentNotifier extends StateNotifier<bool> {
  final LocalStorageService _storage;
  final AuthRepository _authRepo;
  final AuthController _authController;
  final bool _isAuthenticated;

  AdultContentNotifier({
    required bool initialValue,
    required LocalStorageService storage,
    required AuthRepository authRepo,
    required AuthController authController,
    required bool isAuthenticated,
  })  : _storage = storage,
        _authRepo = authRepo,
        _authController = authController,
        _isAuthenticated = isAuthenticated,
        super(initialValue);

  /// Updates the 18+ preference locally and, when authenticated, syncs with AniList.
  /// Returns `true` when the change succeeds, or `false` if remote sync failed.
  Future<bool> setAdultContent(bool enabled) async {
    final previous = state;
    state = enabled;
    await _storage.setBool(LocalStorageService.keyDisplayAdultContent, enabled);

    if (!_isAuthenticated) return true;

    try {
      final synced = await _authRepo.updateDisplayAdultContent(enabled);
      if (!mounted) return true;
      state = synced;
      _authController.updateLocalAdultContent(synced);
      return true;
    } catch (_) {
      if (mounted) {
        state = previous;
        await _storage.setBool(LocalStorageService.keyDisplayAdultContent, previous);
      }
      return false;
    }
  }
}

/// Reactive user preferred title language (`ROMAJI`, `ENGLISH`, or `NATIVE`),
/// synced with AniList `options.titleLanguage` for authenticated users and
/// persisted locally for Guest mode.
final titleLanguageProvider = StateNotifierProvider<TitleLanguageNotifier, String>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final authController = ref.read(authControllerProvider.notifier);
  final authState = ref.watch(authControllerProvider);

  final initialValue = authState is Authenticated
      ? authState.user.titleLanguage
      : storage.titleLanguage;

  return TitleLanguageNotifier(
    initialValue: initialValue,
    storage: storage,
    authRepo: authRepo,
    authController: authController,
    isAuthenticated: authState is Authenticated,
  );
});

class TitleLanguageNotifier extends StateNotifier<String> {
  final LocalStorageService _storage;
  final AuthRepository _authRepo;
  final AuthController _authController;
  final bool _isAuthenticated;

  TitleLanguageNotifier({
    required String initialValue,
    required LocalStorageService storage,
    required AuthRepository authRepo,
    required AuthController authController,
    required bool isAuthenticated,
  })  : _storage = storage,
        _authRepo = authRepo,
        _authController = authController,
        _isAuthenticated = isAuthenticated,
        super(initialValue);

  Future<bool> setTitleLanguage(String language) async {
    final previous = state;
    state = language;
    await _storage.setString(LocalStorageService.keyTitleLanguage, language);

    if (!_isAuthenticated) return true;

    try {
      final synced = await _authRepo.updateTitleLanguage(language);
      if (!mounted) return true;
      state = synced;
      _authController.updateLocalTitleLanguage(synced);
      return true;
    } catch (_) {
      if (mounted) {
        state = previous;
        await _storage.setString(LocalStorageService.keyTitleLanguage, previous);
      }
      return false;
    }
  }
}
