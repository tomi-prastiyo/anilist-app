import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/media_list_repository.dart';

final animeListControllerProvider =
    StateNotifierProvider<MediaListController, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final repo = ref.watch(mediaListRepositoryProvider);
  final auth = ref.watch(authControllerProvider);
  final userId = auth is Authenticated ? auth.user.id : null;
  return MediaListController(repo, userId, 'ANIME');
});

final mangaListControllerProvider =
    StateNotifierProvider<MediaListController, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final repo = ref.watch(mediaListRepositoryProvider);
  final auth = ref.watch(authControllerProvider);
  final userId = auth is Authenticated ? auth.user.id : null;
  return MediaListController(repo, userId, 'MANGA');
});

class MediaListController extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final MediaListRepository _repo;
  final int? _userId;
  final String _type;

  MediaListController(this._repo, this._userId, this._type)
      : super(const AsyncValue.loading()) {
    loadLists();
  }

  Future<void> loadLists() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final lists = await _repo.fetchUserMediaLists(userId: _userId, type: _type);
      state = AsyncValue.data(lists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Increments progress by 1 with instant optimistic UI update
  Future<void> incrementProgress({
    required int entryId,
    required int mediaId,
    required int currentProgress,
    int? maxEpisodesOrChapters,
  }) async {
    final nextProgress = currentProgress + 1;
    final isNowCompleted = maxEpisodesOrChapters != null && nextProgress >= maxEpisodesOrChapters;
    final nextStatus = isNowCompleted ? 'COMPLETED' : null;
    final nowTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Apply optimistic update to local state
    final previousState = state;
    if (state.hasValue) {
      final currentLists = List<Map<String, dynamic>>.from(state.value!);
      for (var list in currentLists) {
        final entries = (list['entries'] as List?)?.cast<Map<String, dynamic>>();
        if (entries != null) {
          for (var entry in entries) {
            if (entry['id'] == entryId) {
              entry['progress'] = nextProgress;
              entry['updatedAt'] = nowTimestamp;
              if (nextStatus != null) {
                entry['status'] = nextStatus;
              }
            }
          }
        }
      }
      state = AsyncValue.data(currentLists);
    }

    // Dispatch background mutation
    try {
      await _repo.saveMediaListEntry(
        id: entryId,
        mediaId: mediaId,
        progress: nextProgress,
        status: nextStatus,
      );
    } catch (e) {
      // Revert optimistic update on error
      state = previousState;
    }
  }

  /// Updates personal score with instant optimistic UI update
  Future<void> updateScore({
    required int entryId,
    required int mediaId,
    required double score,
  }) async {
    final nowTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final previousState = state;
    if (state.hasValue) {
      final currentLists = List<Map<String, dynamic>>.from(state.value!);
      for (var list in currentLists) {
        final entries = (list['entries'] as List?)?.cast<Map<String, dynamic>>();
        if (entries != null) {
          for (var entry in entries) {
            if (entry['id'] == entryId) {
              entry['score'] = score;
              entry['updatedAt'] = nowTimestamp;
            }
          }
        }
      }
      state = AsyncValue.data(currentLists);
    }

    try {
      await _repo.saveMediaListEntry(
        id: entryId,
        mediaId: mediaId,
        score: score,
      );
    } catch (e) {
      state = previousState;
    }
  }
}
