import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final seasonalRepositoryProvider = Provider<SeasonalRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SeasonalRepository(apiClient);
});

class SeasonalRepository {
  final ApiClient _apiClient;

  SeasonalRepository(this._apiClient);

  static const String seasonalMediaQuery = r'''
    query SeasonalQuery($page: Int, $season: MediaSeason, $seasonYear: Int) {
      Page(page: $page, perPage: 24) {
        pageInfo {
          currentPage
          hasNextPage
        }
        media(season: $season, seasonYear: $seasonYear, type: ANIME, sort: [POPULARITY_DESC], isAdult: false) {
          id
          title {
            romaji
            english
            native
            userPreferred
          }
          format
          status
          episodes
          averageScore
          coverImage {
            large
            medium
          }
        }
      }
    }
  ''';

  Future<Map<String, dynamic>> fetchSeasonalAnime({
    required int page,
    required String season,
    required int year,
  }) async {
    final response = await _apiClient.postGraphQL(
      query: seasonalMediaQuery,
      variables: {
        'page': page,
        'season': season,
        'seasonYear': year,
      },
    );
    return response['Page'] as Map<String, dynamic>? ?? {};
  }
}
