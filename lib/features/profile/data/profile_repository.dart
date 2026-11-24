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
        isFollowing
        isFollower
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
            statuses(sort: [COUNT_DESC]) {
              status
              count
              meanScore
              minutesWatched
            }
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
            statuses(sort: [COUNT_DESC]) {
              status
              count
              meanScore
              chaptersRead
            }
            scores {
              score
              count
            }
            genres(sort: [COUNT_DESC]) {
              genre
              count
            }
          }
        }
        favourites {
          anime(page: 1, perPage: 40) {
            nodes {
              id
              type
              format
              averageScore
              title {
                userPreferred
                romaji
                english
              }
              coverImage {
                large
                medium
              }
            }
          }
          manga(page: 1, perPage: 40) {
            nodes {
              id
              type
              format
              averageScore
              title {
                userPreferred
                romaji
                english
              }
              coverImage {
                large
                medium
              }
            }
          }
          characters(page: 1, perPage: 40) {
            nodes {
              id
              name {
                userPreferred
                full
              }
              image {
                large
                medium
              }
            }
          }
          staff(page: 1, perPage: 40) {
            nodes {
              id
              name {
                userPreferred
                full
              }
              image {
                large
                medium
              }
              primaryOccupations
            }
          }
        }
      }
    }
  ''';

  static const String userFollowCountsQuery = r'''
    query UserFollowCountsQuery($userId: Int!) {
      followingPage: Page(page: 1, perPage: 1) {
        pageInfo {
          total
        }
        following(userId: $userId) {
          id
        }
      }
      followersPage: Page(page: 1, perPage: 1) {
        pageInfo {
          total
        }
        followers(userId: $userId) {
          id
        }
      }
    }
  ''';

  static const String userFollowingQuery = r'''
    query UserFollowingQuery($userId: Int!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          hasNextPage
        }
        following(userId: $userId, sort: [USERNAME]) {
          id
          name
          avatar {
            large
            medium
          }
          bannerImage
          about(asHtml: false)
          isFollowing
          isFollower
        }
      }
    }
  ''';

  static const String userFollowersQuery = r'''
    query UserFollowersQuery($userId: Int!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          hasNextPage
        }
        followers(userId: $userId, sort: [USERNAME]) {
          id
          name
          avatar {
            large
            medium
          }
          bannerImage
          about(asHtml: false)
          isFollowing
          isFollower
        }
      }
    }
  ''';

  static const String toggleFollowMutation = r'''
    mutation ToggleFollowMutation($userId: Int) {
      ToggleFollow(userId: $userId) {
        id
        name
        isFollowing
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

  Future<Map<String, int>> fetchFollowCounts({required int userId}) async {
    try {
      final res = await _apiClient.postGraphQL(
        query: userFollowCountsQuery,
        variables: {'userId': userId},
      );
      final followingTotal = res['followingPage']?['pageInfo']?['total'] as int? ?? 0;
      final followersTotal = res['followersPage']?['pageInfo']?['total'] as int? ?? 0;
      return {
        'following': followingTotal,
        'followers': followersTotal,
      };
    } catch (_) {
      return {'following': 0, 'followers': 0};
    }
  }

  Future<Map<String, dynamic>> fetchUserFollowing({
    required int userId,
    required int page,
    int perPage = 25,
  }) async {
    final res = await _apiClient.postGraphQL(
      query: userFollowingQuery,
      variables: {
        'userId': userId,
        'page': page,
        'perPage': perPage,
      },
    );
    return res['Page'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> fetchUserFollowers({
    required int userId,
    required int page,
    int perPage = 25,
  }) async {
    final res = await _apiClient.postGraphQL(
      query: userFollowersQuery,
      variables: {
        'userId': userId,
        'page': page,
        'perPage': perPage,
      },
    );
    return res['Page'] as Map<String, dynamic>? ?? {};
  }

  Future<bool> toggleFollow(int userId) async {
    final res = await _apiClient.postGraphQL(
      query: toggleFollowMutation,
      variables: {'userId': userId},
    );
    return res['ToggleFollow']?['isFollowing'] as bool? ?? false;
  }
}
