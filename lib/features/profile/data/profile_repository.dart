import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});

/// Incremented whenever the user toggles a favourite (anime, manga, character,
/// or staff) so Profile -> Favorites stays synchronized across screens.
final favoritesRevisionProvider = StateProvider<int>((ref) => 0);

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  static const String userDetailQuery = r'''
    query UserDetailQuery($id: Int, $name: String) {
      User(id: $id, name: $name) {
        id
        name
        about(asHtml: false)
        aboutHtml: about(asHtml: true)
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
          anime(page: 1, perPage: 25) {
            pageInfo {
              hasNextPage
            }
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
          manga(page: 1, perPage: 25) {
            pageInfo {
              hasNextPage
            }
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
          characters(page: 1, perPage: 25) {
            pageInfo {
              hasNextPage
            }
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
          staff(page: 1, perPage: 25) {
            pageInfo {
              hasNextPage
            }
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
          studios(page: 1, perPage: 25) {
            pageInfo {
              hasNextPage
            }
            nodes {
              id
              name
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

  static const String updateUserBioMutation = r'''
    mutation UpdateUserBio($about: String) {
      UpdateUser(about: $about) {
        id
        about(asHtml: false)
        aboutHtml: about(asHtml: true)
      }
    }
  ''';

  static const String userFavouritesPageQuery = r'''
    query UserFavouritesPageQuery($id: Int, $name: String, $page: Int!) {
      User(id: $id, name: $name) {
        favourites {
          anime(page: $page, perPage: 25) {
            pageInfo { hasNextPage }
            nodes {
              id
              type
              format
              averageScore
              title { userPreferred romaji english }
              coverImage { large medium }
            }
          }
          manga(page: $page, perPage: 25) {
            pageInfo { hasNextPage }
            nodes {
              id
              type
              format
              averageScore
              title { userPreferred romaji english }
              coverImage { large medium }
            }
          }
          characters(page: $page, perPage: 25) {
            pageInfo { hasNextPage }
            nodes {
              id
              name { userPreferred full }
              image { large medium }
            }
          }
          staff(page: $page, perPage: 25) {
            pageInfo { hasNextPage }
            nodes {
              id
              name { userPreferred full }
              image { large medium }
              primaryOccupations
            }
          }
          studios(page: $page, perPage: 25) {
            pageInfo { hasNextPage }
            nodes {
              id
              name
            }
          }
        }
      }
    }
  ''';

  static const String updateFavouriteOrderMutation = r'''
    mutation UpdateFavouriteOrder(
      $animeIds: [Int],
      $mangaIds: [Int],
      $characterIds: [Int],
      $staffIds: [Int],
      $studioIds: [Int],
      $animeOrder: [Int],
      $mangaOrder: [Int],
      $characterOrder: [Int],
      $staffOrder: [Int],
      $studioOrder: [Int]
    ) {
      UpdateFavouriteOrder(
        animeIds: $animeIds,
        mangaIds: $mangaIds,
        characterIds: $characterIds,
        staffIds: $staffIds,
        studioIds: $studioIds,
        animeOrder: $animeOrder,
        mangaOrder: $mangaOrder,
        characterOrder: $characterOrder,
        staffOrder: $staffOrder,
        studioOrder: $studioOrder
      ) {
        anime { nodes { id } }
        manga { nodes { id } }
        characters { nodes { id } }
        staff { nodes { id } }
        studios { nodes { id } }
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
    final user = res['User'] as Map<String, dynamic>? ?? {};

    // AniList caps Favourites connections at 25/page; paginate every remaining page cleanly.
    final favs = user['favourites'] as Map<String, dynamic>?;
    if (favs != null) {
      const favKeys = ['anime', 'manga', 'characters', 'staff', 'studios'];
      bool anyHasNext(Map<String, dynamic> map) =>
          favKeys.any((k) => map[k]?['pageInfo']?['hasNextPage'] == true);

      final seenIds = <String, Set<int>>{
        for (final key in favKeys)
          key: {
            for (final node in ((favs[key]?['nodes'] as List?) ?? const []))
              if (node is Map && node['id'] is int) node['id'] as int,
          },
      };

      var page = 2;
      var currentFavs = favs;
      while (anyHasNext(currentFavs) && page <= 20) {
        try {
          final pageRes = await _apiClient.postGraphQL(
            query: userFavouritesPageQuery,
            variables: {...variables, 'page': page},
          );
          final nextFavs = pageRes['User']?['favourites'] as Map<String, dynamic>?;
          if (nextFavs == null) break;
          for (final key in favKeys) {
            final existing = (favs[key]?['nodes'] as List?) ?? [];
            final extra = (nextFavs[key]?['nodes'] as List?) ?? [];
            if (extra.isNotEmpty && favs[key] is Map) {
              final uniqueExtra = extra.where((node) {
                if (node is! Map) return false;
                final id = node['id'] as int?;
                if (id == null) return true;
                return seenIds[key]!.add(id);
              }).toList();
              if (uniqueExtra.isNotEmpty) {
                favs[key]['nodes'] = [...existing, ...uniqueExtra];
              }
            }
          }
          currentFavs = nextFavs;
          page++;
        } catch (_) {
          break;
        }
      }
    }

    return user;
  }

  Future<void> updateFavouriteOrder({
    required String categoryKey, // 'ANIME', 'MANGA', 'CHARACTERS', 'STAFF', 'STUDIOS'
    required List<int> orderedIds,
  }) async {
    if (orderedIds.isEmpty) return;
    final orders = List<int>.generate(orderedIds.length, (i) => i + 1);
    final variables = <String, dynamic>{};
    switch (categoryKey) {
      case 'ANIME':
        variables['animeIds'] = orderedIds;
        variables['animeOrder'] = orders;
      case 'MANGA':
        variables['mangaIds'] = orderedIds;
        variables['mangaOrder'] = orders;
      case 'CHARACTERS':
        variables['characterIds'] = orderedIds;
        variables['characterOrder'] = orders;
      case 'STAFF':
        variables['staffIds'] = orderedIds;
        variables['staffOrder'] = orders;
      case 'STUDIOS':
        variables['studioIds'] = orderedIds;
        variables['studioOrder'] = orders;
      default:
        return;
    }

    await _apiClient.postGraphQL(
      query: updateFavouriteOrderMutation,
      variables: variables,
    );
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

  Future<Map<String, dynamic>> updateUserBio(String about) async {
    final res = await _apiClient.postGraphQL(
      query: updateUserBioMutation,
      variables: {'about': about},
    );
    return res['UpdateUser'] as Map<String, dynamic>? ?? {};
  }
}
