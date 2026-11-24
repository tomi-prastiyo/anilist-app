import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  static const String userDetailQuery = r'''
    query UserDetailQuery($id: Int, $name: String) {
      User(id: $id, name: $name) {
        id
        name
        about(asHtml: false)
        avatar {
          large
          medium
        }
        bannerImage
        statistics {
          anime {
            count
            meanScore
            standardDeviation
            minutesWatched
            episodesWatched
            scores {
              score
              count
            }
            formats(sort: [COUNT_DESC]) {
              format
              count
            }
            genres(sort: [COUNT_DESC]) {
              genre
              count
            }
          }
          manga {
            count
            meanScore
            chaptersRead
            volumesRead
          }
        }
        favourites {
          anime(page: 1, perPage: 12) {
            nodes {
              id
              title {
                userPreferred
              }
              coverImage {
                large
                medium
              }
            }
          }
          manga(page: 1, perPage: 12) {
            nodes {
              id
              title {
                userPreferred
              }
              coverImage {
                large
                medium
              }
            }
          }
          characters(page: 1, perPage: 12) {
            nodes {
              id
              name {
                userPreferred
              }
              image {
                medium
              }
            }
          }
          staff(page: 1, perPage: 12) {
            nodes {
              id
              name {
                userPreferred
              }
              image {
                medium
              }
            }
          }
        }
      }
    }
  ''';

  Future<Map<String, dynamic>> fetchUserProfile({int? userId, String? userName}) async {
    final Map<String, dynamic> variables = {};
    if (userId != null && userId > 0) {
      variables['id'] = userId;
    } else if (userName != null && userName.isNotEmpty) {
      variables['name'] = userName;
    }

    final res = await _apiClient.postGraphQL(
      query: userDetailQuery,
      variables: variables,
    );
    return res['User'] as Map<String, dynamic>? ?? {};
  }
}
