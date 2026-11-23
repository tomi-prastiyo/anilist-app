import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CalendarRepository(apiClient);
});

class CalendarRepository {
  final ApiClient _apiClient;

  CalendarRepository(this._apiClient);

  static const String airingScheduleQuery = r'''
    query AiringScheduleQuery($airingAtGreater: Int, $airingAtLesser: Int, $page: Int) {
      Page(page: $page, perPage: 50) {
        pageInfo {
          currentPage
          hasNextPage
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
              romaji
              english
              native
              userPreferred
            }
            format
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

  Future<List<Map<String, dynamic>>> fetchScheduleForDay(DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 1000;
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch ~/ 1000;

    final response = await _apiClient.postGraphQL(
      query: airingScheduleQuery,
      variables: {
        'page': 1,
        'airingAtGreater': startOfDay,
        'airingAtLesser': endOfDay,
      },
    );

    final page = response['Page'] as Map<String, dynamic>?;
    final schedules = (page?['airingSchedules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return schedules;
  }
}
