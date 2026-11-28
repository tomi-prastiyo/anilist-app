import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return AuthRepository(apiClient, secureStorage, localStorage);
});

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  AuthRepository(this._apiClient, this._secureStorage, this._localStorage);

  static const String viewerQuery = r'''
    query ViewerQuery {
      Viewer {
        id
        name
        about(asHtml: false)
        avatar {
          large
          medium
        }
        bannerImage
        options {
          titleLanguage
          profileColor
          displayAdultContent
        }
        mediaListOptions {
          scoreFormat
        }
        unreadNotificationCount
      }
    }
  ''';

  Future<UserModel> getViewer() async {
    final data = await _apiClient.postGraphQL(query: viewerQuery);
    final viewerData = data['Viewer'] as Map<String, dynamic>?;
    if (viewerData == null) {
      throw ApiException('Failed to retrieve viewer details');
    }
    final user = UserModel.fromJson(viewerData);
    
    // Sync to local settings
    _localStorage.setInt(LocalStorageService.keyViewerId, user.id);
    _localStorage.titleLanguage = user.titleLanguage;
    _localStorage.scoreFormat = user.scoreFormat;
    _localStorage.displayAdultContent = user.displayAdultContent;

    return user;
  }

  static const String updateAdultContentMutation = r'''
    mutation UpdateAdultContent($displayAdultContent: Boolean) {
      UpdateUser(displayAdultContent: $displayAdultContent) {
        id
        options {
          displayAdultContent
        }
      }
    }
  ''';

  Future<bool> updateDisplayAdultContent(bool enabled) async {
    final data = await _apiClient.postGraphQL(
      query: updateAdultContentMutation,
      variables: {'displayAdultContent': enabled},
    );
    final updated = data['UpdateUser']?['options']?['displayAdultContent'] as bool? ?? enabled;
    _localStorage.displayAdultContent = updated;
    return updated;
  }

  static const String updateTitleLanguageMutation = r'''
    mutation UpdateTitleLanguage($titleLanguage: UserTitleLanguage) {
      UpdateUser(titleLanguage: $titleLanguage) {
        id
        options {
          titleLanguage
        }
      }
    }
  ''';

  Future<String> updateTitleLanguage(String language) async {
    final data = await _apiClient.postGraphQL(
      query: updateTitleLanguageMutation,
      variables: {'titleLanguage': language},
    );
    final updated = data['UpdateUser']?['options']?['titleLanguage'] as String? ?? language;
    _localStorage.titleLanguage = updated;
    return updated;
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.saveAccessToken(token);
    _localStorage.isGuest = false;
  }

  Future<void> clearAuth() async {
    await _secureStorage.clearAccessToken();
    _localStorage.isGuest = false;
  }

  void loginAsGuest() {
    _localStorage.isGuest = true;
  }

  bool get isGuest => _localStorage.isGuest;

  Future<bool> hasToken() => _secureStorage.hasAccessToken();
}
