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
    query HomeDataQuery(
      $season: MediaSeason,
      $seasonYear: Int,
      $airingAtGreater: Int,
      $airingAtLesser: Int
    ) {
      spotlightMedia: Page(page: 1, perPage: 5) {
        media(type: ANIME, sort: [TRENDING_DESC], isAdult: false) {
          ...HomeMediaFragment
        }
      }
      trendingAnime: Page(page: 1, perPage: 10) {
        media(type: ANIME, sort: [TRENDING_DESC], isAdult: false) {
          ...HomeMediaFragment
        }
      }
      popularSeason: Page(page: 1, perPage: 10) {
        media(type: ANIME, season: $season, seasonYear: $seasonYear, sort: [POPULARITY_DESC], isAdult: false) {
          ...HomeMediaFragment
        }
      }
      trendingManga: Page(page: 1, perPage: 10) {
        media(type: MANGA, sort: [TRENDING_DESC], isAdult: false) {
          ...HomeMediaFragment
        }
      }
      topRated: Page(page: 1, perPage: 10) {
        media(type: ANIME, sort: [SCORE_DESC], isAdult: false) {
          ...HomeMediaFragment
        }
      }
      airingToday: Page(page: 1, perPage: 25) {
        airingSchedules(airingAt_greater: $airingAtGreater, airingAt_lesser: $airingAtLesser, sort: [TIME]) {
          id
          airingAt
          timeUntilAiring
          episode
          media {
            id
            title {
              userPreferred
              romaji
              english
            }
            format
            genres
            coverImage {
              large
              medium
            }
          }
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
      genres
      description(asHtml: false)
      coverImage {
        extraLarge
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

  static const String airingScheduleQuery = r'''
    query AiringScheduleQuery($airingAtGreater: Int, $airingAtLesser: Int, $page: Int) {
      Page(page: $page, perPage: 50) {
        pageInfo {
          hasNextPage
          currentPage
        }
        airingSchedules(
          airingAt_greater: $airingAtGreater,
          airingAt_lesser: $airingAtLesser,
          sort: [TIME]
        ) {
          id
          airingAt
          timeUntilAiring
          episode
          media {
            id
            title {
              userPreferred
              romaji
              english
            }
            format
            genres
            averageScore
            coverImage {
              large
              medium
            }
          }
        }
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
    final now = DateTime.now();
    // Query airing anime from beginning of today up to 48 hours ahead for rich upcoming list
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
    final endOfWindow = now.add(const Duration(hours: 48)).millisecondsSinceEpoch ~/ 1000;

    return await _apiClient.postGraphQL(
      query: homeDataQuery,
      variables: {
        'season': season,
        'seasonYear': year,
        'airingAtGreater': startOfDay,
        'airingAtLesser': endOfWindow,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchAiringSchedule({
    required int airingAtGreater,
    required int airingAtLesser,
    int page = 1,
  }) async {
    final response = await _apiClient.postGraphQL(
      query: airingScheduleQuery,
      variables: {
        'airingAtGreater': airingAtGreater,
        'airingAtLesser': airingAtLesser,
        'page': page,
      },
    );
    final pageData = response['Page'] as Map<String, dynamic>?;
    return (pageData?['airingSchedules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }
}
