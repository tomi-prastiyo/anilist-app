import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsRepository(apiClient);
});

class NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepository(this._apiClient);

  static const String notificationsQuery = r'''
    query NotificationsQuery($page: Int, $resetNotificationCount: Boolean) {
      Page(page: $page, perPage: 25) {
        pageInfo {
          currentPage
          hasNextPage
        }
        notifications(resetNotificationCount: $resetNotificationCount) {
          __typename
          ... on ActivityLikeNotification {
            id
            createdAt
            user {
              name
              avatar {
                medium
              }
            }
          }
          ... on ActivityReplyNotification {
            id
            createdAt
            user {
              name
              avatar {
                medium
              }
            }
          }
          ... on AiringNotification {
            id
            episode
            createdAt
            media {
              title {
                userPreferred
              }
              coverImage {
                medium
              }
            }
          }
          ... on FollowingNotification {
            id
            createdAt
            user {
              name
              avatar {
                medium
              }
            }
          }
        }
      }
    }
  ''';

  Future<List<Map<String, dynamic>>> fetchNotifications({
    required int page,
    bool resetCount = true,
  }) async {
    final res = await _apiClient.postGraphQL(
      query: notificationsQuery,
      variables: {
        'page': page,
        'resetNotificationCount': resetCount,
      },
    );
    final pageData = res['Page'] as Map<String, dynamic>?;
    return (pageData?['notifications'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }
}
