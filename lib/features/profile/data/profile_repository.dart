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
    query UserDetailQuery($id: Int) {
      User(id: $id) {
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
            scores(sort: [SCORE]) {
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
          anime(page: 1, perPage: 10) {
            nodes {
              id
              title {
                userPreferred
              }
              coverImage {
                medium
              }
            }
          }
          characters(page: 1, perPage: 10) {
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

  Future<Map<String, dynamic>> fetchUserProfile(int userId) async {
    final res = await _apiClient.postGraphQL(
      query: userDetailQuery,
      variables: {'id': userId},
    );
    return res['User'] as Map<String, dynamic>? ?? {};
  }
}
