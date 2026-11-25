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
          ... on AiringNotification {
            id
            type
            animeId
            episode
            contexts
            createdAt
            media {
              id
              title {
                userPreferred
                romaji
              }
              coverImage {
                medium
                large
              }
              type
            }
          }
          ... on FollowingNotification {
            id
            userId
            type
            context
            createdAt
            user {
              id
              name
              avatar {
                medium
              }
            }
          }
          ... on ActivityLikeNotification {
            id
            userId
            type
            activityId
            context
            createdAt
            user {
              id
              name
              avatar {
                medium
              }
            }
            activity {
              __typename
              ... on ListActivity {
                id
                status
                progress
                media {
                  id
                  type
                  title {
                    userPreferred
                    romaji
                    english
                  }
                  coverImage {
                    medium
                    large
                  }
                }
              }
              ... on TextActivity {
                id
                text
              }
            }
          }
          ... on ActivityReplyNotification {
            id
            userId
            type
            activityId
            context
            createdAt
            user {
              id
              name
              avatar {
                medium
              }
            }
            activity {
              __typename
              ... on ListActivity {
                id
                status
                progress
                media {
                  id
                  type
                  title {
                    userPreferred
                    romaji
                    english
                  }
                  coverImage {
                    medium
                    large
                  }
                }
              }
              ... on TextActivity {
                id
                text
              }
            }
          }
          ... on ActivityMentionNotification {
            id
            userId
            type
            activityId
            context
            createdAt
            user {
              id
              name
              avatar {
                medium
              }
            }
          }
          ... on ActivityMessageNotification {
            id
            userId
            type
            activityId
            context
            createdAt
            user {
              id
              name
              avatar {
                medium
              }
            }
          }
          ... on ActivityReplyLikeNotification {
            id
            userId
            type
            activityId
            context
            createdAt
            user {
              id
              name
              avatar {
                medium
              }
            }
          }
          ... on ActivityReplySubscribedNotification {
            id
            userId
            type
            activityId
            context
            createdAt
            user {
              id
              name
              avatar {
                medium
              }
            }
          }
          ... on RelatedMediaAdditionNotification {
            id
            type
            mediaId
            context
            createdAt
            media {
              id
              title {
                userPreferred
              }
              coverImage {
                medium
              }
              type
            }
          }
          ... on MediaDataChangeNotification {
            id
            type
            mediaId
            context
            reason
            createdAt
            media {
              id
              title {
                userPreferred
              }
              coverImage {
                medium
              }
              type
            }
          }
          ... on MediaMergeNotification {
            id
            type
            mediaId
            deletedMediaTitles
            context
            reason
            createdAt
            media {
              id
              title {
                userPreferred
              }
              coverImage {
                medium
              }
              type
            }
          }
          ... on MediaDeletionNotification {
            id
            type
            deletedMediaTitle
            context
            reason
            createdAt
          }
          ... on ThreadCommentMentionNotification {
            id
            userId
            type
            commentId
            context
            createdAt
            thread {
              id
              title
              siteUrl
            }
            user {
              id
              name
              avatar {
                medium
              }
            }
          }
          ... on ThreadCommentReplyNotification {
            id
            userId
            type
            commentId
            context
            createdAt
            thread {
              id
              title
              siteUrl
            }
            user {
              id
              name
              avatar {
                medium
              }
            }
          }
          ... on ThreadCommentLikeNotification {
            id
            userId
            type
            commentId
            context
            createdAt
            thread {
              id
              title
              siteUrl
            }
            user {
              id
              name
              avatar {
                medium
              }
            }
          }
          ... on ThreadLikeNotification {
            id
            userId
            type
            threadId
            context
            createdAt
            thread {
              id
              title
              siteUrl
            }
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
    }
  ''';

  static const String viewerUnreadQuery = r'''
    query ViewerUnreadCountQuery {
      Viewer {
        unreadNotificationCount
      }
    }
  ''';

  Future<int> fetchUnreadCount() async {
    final res = await _apiClient.postGraphQL(query: viewerUnreadQuery);
    final viewer = res['Viewer'] as Map<String, dynamic>?;
    return viewer?['unreadNotificationCount'] as int? ?? 0;
  }

  Future<void> resetServerUnreadCount() async {
    await _apiClient.postGraphQL(
      query: notificationsQuery,
      variables: {
        'page': 1,
        'resetNotificationCount': true,
      },
    );
  }

  Future<Map<String, dynamic>> fetchNotificationsWithPageInfo({
    required int page,
    bool resetCount = false,
  }) async {
    final res = await _apiClient.postGraphQL(
      query: notificationsQuery,
      variables: {
        'page': page,
        'resetNotificationCount': resetCount,
      },
    );
    final pageData = res['Page'] as Map<String, dynamic>?;
    final pageInfo = pageData?['pageInfo'] as Map<String, dynamic>?;
    final list = (pageData?['notifications'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return {
      'notifications': list,
      'hasNextPage': pageInfo?['hasNextPage'] as bool? ?? false,
      'currentPage': pageInfo?['currentPage'] as int? ?? page,
    };
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    required int page,
    bool resetCount = false,
  }) async {
    final result = await fetchNotificationsWithPageInfo(page: page, resetCount: resetCount);
    return (result['notifications'] as List).cast<Map<String, dynamic>>();
  }
}
