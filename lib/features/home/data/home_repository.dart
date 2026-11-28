import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeRepository(apiClient);
});

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository(this._apiClient);

  static const String homeAiringQuery = r'''
    query HomeAiringQuery(
      $airingAtGreater: Int,
      $airingAtLesser: Int,
      $mediaIds: [Int]
    ) {
      airingToday: Page(page: 1, perPage: 30) {
        airingSchedules(
          airingAt_greater: $airingAtGreater,
          airingAt_lesser: $airingAtLesser,
          mediaId_in: $mediaIds,
          sort: [TIME]
        ) {
          id
          airingAt
          timeUntilAiring
          episode
          media {
            id
            isAdult
            title {
              userPreferred
              romaji
              english
            }
            format
            genres
            bannerImage
            coverImage {
              extraLarge
              large
              medium
            }
          }
        }
      }
    }
  ''';

  static const String airingScheduleQuery = r'''
    query AiringScheduleQuery($airingAtGreater: Int, $airingAtLesser: Int, $mediaIds: [Int], $page: Int) {
      Page(page: $page, perPage: 50) {
        pageInfo {
          hasNextPage
          currentPage
        }
        airingSchedules(
          airingAt_greater: $airingAtGreater,
          airingAt_lesser: $airingAtLesser,
          mediaId_in: $mediaIds,
          sort: [TIME]
        ) {
          id
          airingAt
          timeUntilAiring
          episode
          media {
            id
            isAdult
            title {
              userPreferred
              romaji
              english
            }
            format
            genres
            averageScore
            bannerImage
            coverImage {
              extraLarge
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

  Future<Map<String, dynamic>> fetchHomeData({
    List<int>? mediaIds,
    bool includeAdult = false,
  }) async {
    if (mediaIds == null || mediaIds.isEmpty) {
      return {
        'airingToday': {'airingSchedules': <Map<String, dynamic>>[]},
      };
    }

    final now = DateTime.now();
    // Query airing anime in user's list from start of today up to 48 hours ahead
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
    final endOfWindow = now.add(const Duration(hours: 48)).millisecondsSinceEpoch ~/ 1000;

    final data = await _apiClient.postGraphQL(
      query: homeAiringQuery,
      variables: {
        'airingAtGreater': startOfDay,
        'airingAtLesser': endOfWindow,
        'mediaIds': mediaIds,
      },
    );
    final raw = (data['airingToday']?['airingSchedules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final safe = includeAdult
        ? raw
        : raw.where((s) => s['media']?['isAdult'] != true).toList();
    return {
      'airingToday': {'airingSchedules': safe},
    };
  }

  Future<List<Map<String, dynamic>>> fetchAiringSchedule({
    required int airingAtGreater,
    required int airingAtLesser,
    List<int>? mediaIds,
    int page = 1,
    bool includeAdult = false,
  }) async {
    final vars = <String, dynamic>{
      'airingAtGreater': airingAtGreater,
      'airingAtLesser': airingAtLesser,
      'page': page,
    };
    if (mediaIds != null && mediaIds.isNotEmpty) {
      vars['mediaIds'] = mediaIds;
    }

    final response = await _apiClient.postGraphQL(
      query: airingScheduleQuery,
      variables: vars,
    );
    final pageData = response['Page'] as Map<String, dynamic>?;
    final list = (pageData?['airingSchedules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return includeAdult
        ? list
        : list.where((s) => s['media']?['isAdult'] != true).toList();
  }
}
