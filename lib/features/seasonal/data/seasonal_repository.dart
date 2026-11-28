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
    query SeasonalQuery($page: Int, $season: MediaSeason, $seasonYear: Int, $isAdult: Boolean) {
      Page(page: $page, perPage: 24) {
        pageInfo {
          currentPage
          hasNextPage
        }
        media(season: $season, seasonYear: $seasonYear, type: ANIME, sort: [POPULARITY_DESC], isAdult: $isAdult) {
          id
          isAdult
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
          genres
          seasonYear
          season
          bannerImage
          coverImage {
            extraLarge
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
    bool includeAdult = false,
  }) async {
    final vars = <String, dynamic>{
      'page': page,
      'season': season,
      'seasonYear': year,
    };
    if (!includeAdult) vars['isAdult'] = false;

    final response = await _apiClient.postGraphQL(
      query: seasonalMediaQuery,
      variables: vars,
    );
    return response['Page'] as Map<String, dynamic>? ?? {};
  }
}
