import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final mediaDetailRepositoryProvider = Provider<MediaDetailRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MediaDetailRepository(apiClient);
});

class MediaDetailRepository {
  final ApiClient _apiClient;

  MediaDetailRepository(this._apiClient);

  static const String mediaQuery = r'''
    query MediaQuery($id: Int) {
      Media(id: $id) {
        id
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
        tags {
          id
          name
          description
          rank
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
              coverImage {
                medium
              }
            }
          }
        }
        characters(role: MAIN, perPage: 12) {
          nodes {
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
        staff(perPage: 8) {
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
        studios(isMain: true) {
          edges {
            isMain
            node {
              id
              name
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
}
