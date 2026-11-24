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
    query ActivityListQuery($page: Int, $isFollowing: Boolean) {
      Page(page: $page, perPage: 20) {
        pageInfo {
          currentPage
          hasNextPage
        }
        activities(isFollowing: $isFollowing, sort: [ID_DESC]) {
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
    bool isFollowing = false,
  }) async {
    final response = await _apiClient.postGraphQL(
      query: activityListQuery,
      variables: {
        'page': page,
        'isFollowing': isFollowing,
      },
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
}
