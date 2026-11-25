import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final mediaListRepositoryProvider = Provider<MediaListRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MediaListRepository(apiClient);
});

class MediaListRepository {
  final ApiClient _apiClient;

  MediaListRepository(this._apiClient);

  static const String mediaListCollectionQuery = r'''
    query MediaListCollectionQuery($userId: Int, $type: MediaType) {
      MediaListCollection(userId: $userId, type: $type) {
        lists {
          name
          isCustomList
          status
          entries {
            id
            status
            score
            progress
            progressVolumes
            repeat
            notes
            private
            startedAt {
              year
              month
              day
            }
            completedAt {
              year
              month
              day
            }
            updatedAt
            media {
              id
              title {
                romaji
                english
                native
                userPreferred
              }
              type
              format
              status
              episodes
              chapters
              volumes
              averageScore
              bannerImage
              coverImage {
                extraLarge
                large
                medium
              }
              nextAiringEpisode {
                episode
                timeUntilAiring
              }
            }
          }
        }
      }
    }
  ''';

  static const String saveMediaListEntryMutation = r'''
    mutation SaveMediaListEntry(
      $id: Int,
      $mediaId: Int,
      $status: MediaListStatus,
      $score: Float,
      $progress: Int,
      $progressVolumes: Int,
      $repeat: Int,
      $notes: String,
      $isPrivate: Boolean,
      $startedAt: FuzzyDateInput,
      $completedAt: FuzzyDateInput
    ) {
      SaveMediaListEntry(
        id: $id,
        mediaId: $mediaId,
        status: $status,
        score: $score,
        progress: $progress,
        progressVolumes: $progressVolumes,
        repeat: $repeat,
        notes: $notes,
        private: $isPrivate,
        startedAt: $startedAt,
        completedAt: $completedAt
      ) {
        id
        status
        score
        progress
        progressVolumes
        repeat
        notes
        private
        startedAt {
          year
          month
          day
        }
        completedAt {
          year
          month
          day
        }
        updatedAt
      }
    }
  ''';

  static const String deleteMediaListEntryMutation = r'''
    mutation DeleteMediaListEntry($id: Int) {
      DeleteMediaListEntry(id: $id) {
        deleted
      }
    }
  ''';

  Future<List<Map<String, dynamic>>> fetchUserMediaLists({
    required int userId,
    required String type, // ANIME or MANGA
  }) async {
    final response = await _apiClient.postGraphQL(
      query: mediaListCollectionQuery,
      variables: {
        'userId': userId,
        'type': type,
      },
    );

    final collection = response['MediaListCollection'] as Map<String, dynamic>?;
    final lists = (collection?['lists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return lists;
  }

  Future<Map<String, dynamic>> saveMediaListEntry({
    int? id,
    required int mediaId,
    String? status,
    double? score,
    int? progress,
    int? progressVolumes,
    int? repeat,
    String? notes,
    bool? isPrivate,
    Map<String, int>? startedAt,
    Map<String, int>? completedAt,
  }) async {
    final Map<String, dynamic> vars = {'mediaId': mediaId};
    if (id != null) vars['id'] = id;
    if (status != null) vars['status'] = status;
    if (score != null) vars['score'] = score;
    if (progress != null) vars['progress'] = progress;
    if (progressVolumes != null) vars['progressVolumes'] = progressVolumes;
    if (repeat != null) vars['repeat'] = repeat;
    if (notes != null) vars['notes'] = notes;
    if (isPrivate != null) vars['isPrivate'] = isPrivate;
    if (startedAt != null) vars['startedAt'] = startedAt;
    if (completedAt != null) vars['completedAt'] = completedAt;

    final response = await _apiClient.postGraphQL(
      query: saveMediaListEntryMutation,
      variables: vars,
    );

    return response['SaveMediaListEntry'] as Map<String, dynamic>? ?? {};
  }

  Future<bool> deleteMediaListEntry(int id) async {
    final response = await _apiClient.postGraphQL(
      query: deleteMediaListEntryMutation,
      variables: {'id': id},
    );
    return response['DeleteMediaListEntry']?['deleted'] == true;
  }
}
