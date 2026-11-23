import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeRepository(apiClient);
});

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository(this._apiClient);

  static const String homeDataQuery = r'''
    query HomeDataQuery($season: MediaSeason, $seasonYear: Int) {
      trendingAnime: Page(page: 1, perPage: 10) {
        media(type: ANIME, sort: [TRENDING_DESC], isAdult: false) {
          ...HomeMediaFragment
        }
      }
      trendingManga: Page(page: 1, perPage: 10) {
        media(type: MANGA, sort: [TRENDING_DESC], isAdult: false) {
          ...HomeMediaFragment
        }
      }
      popularSeason: Page(page: 1, perPage: 10) {
        media(type: ANIME, season: $season, seasonYear: $seasonYear, sort: [POPULARITY_DESC], isAdult: false) {
          ...HomeMediaFragment
        }
      }
      topRated: Page(page: 1, perPage: 10) {
        media(type: ANIME, sort: [SCORE_DESC], isAdult: false) {
          ...HomeMediaFragment
        }
      }
    }

    fragment HomeMediaFragment on Media {
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
      chapters
      averageScore
      bannerImage
      coverImage {
        large
        medium
      }
      nextAiringEpisode {
        airingAt
        timeUntilAiring
        episode
      }
    }
  ''';

  static String getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 1 && month <= 3) return 'WINTER';
    if (month >= 4 && month <= 6) return 'SPRING';
    if (month >= 7 && month <= 9) return 'SUMMER';
    return 'FALL';
  }

  static int getCurrentYear() => DateTime.now().year;

  Future<Map<String, dynamic>> fetchHomeData() async {
    final season = getCurrentSeason();
    final year = getCurrentYear();

    return await _apiClient.postGraphQL(
      query: homeDataQuery,
      variables: {
        'season': season,
        'seasonYear': year,
      },
    );
  }
}
