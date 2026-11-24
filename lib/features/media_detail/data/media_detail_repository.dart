import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final mediaDetailRepositoryProvider = Provider<MediaDetailRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MediaDetailRepository(apiClient);
});

class MediaDetailRepository {
  final ApiClient _apiClient;
  final Dio _themesDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'AL-chan/1.0',
      },
    ),
  );

  MediaDetailRepository(this._apiClient);

  static const String mediaQuery = r'''
    query MediaQuery($id: Int) {
      Media(id: $id) {
        id
        idMal
        title {
          romaji
          english
          native
          userPreferred
        }
        type
        format
        status
        description(asHtml: false)
        startDate {
          year
          month
          day
        }
        endDate {
          year
          month
          day
        }
        season
        seasonYear
        episodes
        duration
        chapters
        volumes
        countryOfOrigin
        source
        coverImage {
          extraLarge
          large
          medium
        }
        bannerImage
        genres
        synonyms
        averageScore
        meanScore
        popularity
        favourites
        isFavourite
        trailer {
          id
          site
          thumbnail
        }
        rankings {
          id
          rank
          type
          context
          year
          season
        }
        tags {
          id
          name
          description
          rank
          isMediaSpoiler
        }
        externalLinks {
          id
          url
          site
          icon
          color
        }
        relations {
          edges {
            relationType
            node {
              id
              title {
                userPreferred
                romaji
              }
              format
              type
              status
              coverImage {
                medium
              }
            }
          }
        }
        characters(perPage: 25, sort: [ROLE, RELEVANCE, ID]) {
          edges {
            role
            node {
              id
              name {
                userPreferred
                full
              }
              image {
                medium
              }
            }
            voiceActors(language: JAPANESE, sort: [RELEVANCE, ID]) {
              id
              name {
                userPreferred
                full
              }
              image {
                medium
              }
              language
            }
          }
        }
        staff(perPage: 25, sort: [RELEVANCE, ID]) {
          edges {
            role
            node {
              id
              name {
                userPreferred
                full
              }
              image {
                medium
              }
            }
          }
        }
        studios {
          edges {
            isMain
            node {
              id
              name
            }
          }
        }
        recommendations(perPage: 8, sort: [RATING_DESC]) {
          nodes {
            mediaRecommendation {
              id
              title {
                userPreferred
              }
              format
              type
              coverImage {
                medium
              }
              averageScore
            }
          }
        }
        mediaListEntry {
          id
          status
          score
          progress
          progressVolumes
          repeat
          notes
          private
        }
      }
    }
  ''';

  static const String toggleFavouriteMutation = r'''
    mutation ToggleFavourite($animeId: Int, $mangaId: Int) {
      ToggleFavourite(animeId: $animeId, mangaId: $mangaId) {
        anime {
          nodes {
            id
          }
        }
        manga {
          nodes {
            id
          }
        }
      }
    }
  ''';

  Future<Map<String, dynamic>> fetchMediaDetail(int mediaId) async {
    final response = await _apiClient.postGraphQL(
      query: mediaQuery,
      variables: {'id': mediaId},
    );
    return response['Media'] as Map<String, dynamic>? ?? {};
  }

  Future<void> toggleFavourite({int? animeId, int? mangaId}) async {
    final Map<String, dynamic> vars = {};
    if (animeId != null) vars['animeId'] = animeId;
    if (mangaId != null) vars['mangaId'] = mangaId;

    await _apiClient.postGraphQL(
      query: toggleFavouriteMutation,
      variables: vars,
    );
  }

  /// Fetches Opening & Ending theme songs from AniSongDB asynchronously.
  Future<Map<String, List<Map<String, dynamic>>>> fetchMediaThemes({
    required int anilistId,
    required String queryTitle,
  }) async {
    try {
      final response = await _themesDio.post(
        'https://anisongdb.com/api/search_request',
        data: {
          'and_logic': false,
          'ignore_duplicate': true,
          'anime_search_filter': {
            'search': queryTitle,
            'partial_match': true,
          },
        },
      );

      final list = (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
      final List<Map<String, dynamic>> openings = [];
      final List<Map<String, dynamic>> endings = [];
      final List<Map<String, dynamic>> insertSongs = [];

      for (final item in list) {
        // Match either by linked anilist id if present or general results
        final linkedAnilist = item['linked_ids']?['anilist'] as int?;
        if (linkedAnilist != null && linkedAnilist != anilistId) {
          // If explicitly linked to a different anime, skip
          continue;
        }

        final songType = item['songType'] as String? ?? 'Theme';
        final songData = {
          'type': songType,
          'name': item['songName'] as String? ?? 'Unknown Title',
          'artist': item['songArtist'] as String? ?? 'Unknown Artist',
          'composer': item['songComposer'] as String?,
          'arranger': item['songArranger'] as String?,
          'audio': item['audio'] as String?,
          'hq': item['HQ'] as String?,
        };

        if (songType.toLowerCase().startsWith('opening')) {
          openings.add(songData);
        } else if (songType.toLowerCase().startsWith('ending')) {
          endings.add(songData);
        } else {
          insertSongs.add(songData);
        }
      }

      return {
        'openings': openings,
        'endings': endings,
        'insertSongs': insertSongs,
      };
    } catch (_) {
      // Return empty if offline or not found
      return {
        'openings': [],
        'endings': [],
        'insertSongs': [],
      };
    }
  }

  static const String followingMediaListQuery = r'''
    query FollowingMediaListQuery($mediaId: Int) {
      Page(page: 1, perPage: 20) {
        mediaList(mediaId: $mediaId, isFollowing: true, sort: [UPDATED_TIME_DESC]) {
          id
          status
          score
          progress
          progressVolumes
          updatedAt
          user {
            id
            name
            avatar {
              medium
            }
          }
        }
      }
    }
  ''';

  Future<List<Map<String, dynamic>>> fetchFollowingMediaList(int mediaId) async {
    try {
      final res = await _apiClient.postGraphQL(
        query: followingMediaListQuery,
        variables: {'mediaId': mediaId},
      );
      final pageData = res['Page'] as Map<String, dynamic>?;
      return (pageData?['mediaList'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }
}
