import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ActivityRepository(apiClient);
});

class ActivityRepository {
  final ApiClient _apiClient;

  ActivityRepository(this._apiClient);

  static const String activityListQuery = r'''
    query ActivityListQuery($page: Int, $userId: Int, $isFollowing: Boolean) {
      Page(page: $page, perPage: 20) {
        pageInfo {
          currentPage
          hasNextPage
        }
        activities(userId: $userId, isFollowing: $isFollowing, sort: [ID_DESC]) {
          __typename
          ... on TextActivity {
            id
            text(asHtml: false)
            replyCount
            likeCount
            isLiked
            createdAt
            user {
              id
              name
              avatar {
                medium
              }
            }
          }
          ... on ListActivity {
            id
            status
            progress
            replyCount
            likeCount
            isLiked
            createdAt
            user {
              id
              name
              avatar {
                medium
              }
            }
            media {
              id
              title {
                userPreferred
              }
              coverImage {
                medium
              }
            }
          }
        }
      }
    }
  ''';

  static const String activityRepliesQuery = r'''
    query ActivityRepliesQuery($activityId: Int, $page: Int) {
      Page(page: $page, perPage: 25) {
        pageInfo {
          total
          hasNextPage
          currentPage
        }
        activityReplies(activityId: $activityId) {
          id
          text(asHtml: false)
          likeCount
          isLiked
          createdAt
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

  static const String saveActivityReplyMutation = r'''
    mutation SaveActivityReplyMutation($activityId: Int, $text: String) {
      SaveActivityReply(activityId: $activityId, text: $text) {
        id
        text(asHtml: false)
        likeCount
        isLiked
        createdAt
        user {
          id
          name
          avatar {
            medium
          }
        }
      }
    }
  ''';

  static const String toggleLikeMutation = r'''
    mutation ToggleLikeMutation($id: Int, $type: LikeableType) {
      ToggleLikeV2(id: $id, type: $type) {
        __typename
      }
    }
  ''';

  static const String saveTextActivityMutation = r'''
    mutation SaveTextActivity($text: String) {
      SaveTextActivity(text: $text) {
        id
        text
      }
    }
  ''';

  Future<Map<String, dynamic>> fetchActivities({
    required int page,
    int? userId,
    bool? isFollowing,
  }) async {
    final variables = <String, dynamic>{
      'page': page,
    };
    if (userId != null && userId > 0) {
      variables['userId'] = userId;
    } else if (isFollowing != null) {
      variables['isFollowing'] = isFollowing;
    }

    final response = await _apiClient.postGraphQL(
      query: activityListQuery,
      variables: variables,
    );
    return response['Page'] as Map<String, dynamic>? ?? {};
  }

  Future<void> toggleLike(int activityId) async {
    await _apiClient.postGraphQL(
      query: toggleLikeMutation,
      variables: {
        'id': activityId,
        'type': 'ACTIVITY',
      },
    );
  }

  Future<void> saveTextActivity(String text) async {
    await _apiClient.postGraphQL(
      query: saveTextActivityMutation,
      variables: {'text': text},
    );
  }

  Future<Map<String, dynamic>> fetchActivityReplies({
    required int activityId,
    int page = 1,
  }) async {
    final response = await _apiClient.postGraphQL(
      query: activityRepliesQuery,
      variables: {
        'activityId': activityId,
        'page': page,
      },
    );
    return response['Page'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> saveActivityReply({
    required int activityId,
    required String text,
  }) async {
    final response = await _apiClient.postGraphQL(
      query: saveActivityReplyMutation,
      variables: {
        'activityId': activityId,
        'text': text,
      },
    );
    return response['SaveActivityReply'] as Map<String, dynamic>? ?? {};
  }

  Future<void> toggleReplyLike(int replyId) async {
    await _apiClient.postGraphQL(
      query: toggleLikeMutation,
      variables: {
        'id': replyId,
        'type': 'ACTIVITY_REPLY',
      },
    );
  }
}
