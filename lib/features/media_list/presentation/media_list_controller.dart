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

  Future<void> _updateEntryOptimistically({
    required int entryId,
    required Map<String, dynamic> Function(Map<String, dynamic> entry) transform,
    required Future<void> Function() request,
  }) async {
    final previousState = state;
    if (state.hasValue) {
      final updatedLists = state.value!.map((group) {
        final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>();
        if (entries == null) return group;

        var groupModified = false;
        final updatedEntries = entries.map((entry) {
          if (entry['id'] != entryId) return entry;
          groupModified = true;
          return transform(Map<String, dynamic>.from(entry));
        }).toList();

        if (!groupModified) return group;
        return {
          ...group,
          'entries': updatedEntries,
        };
      }).toList();

      state = AsyncValue.data(updatedLists);
    }

    try {
      await request();
    } catch (_) {
      state = previousState;
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

    await _updateEntryOptimistically(
      entryId: entryId,
      transform: (entry) {
        entry['progress'] = nextProgress;
        entry['updatedAt'] = nowTimestamp;
        if (nextStatus != null) {
          entry['status'] = nextStatus;
        }
        return entry;
      },
      request: () => _repo.saveMediaListEntry(
        id: entryId,
        mediaId: mediaId,
        progress: nextProgress,
        status: nextStatus,
      ),
    );
  }

  /// Increments manga volume progress (`progressVolumes`) by 1 optimistically.
  Future<void> incrementVolume({
    required int entryId,
    required int mediaId,
    required int currentVolumes,
    int? maxVolumes,
  }) async {
    final nextVolumes = maxVolumes != null && currentVolumes >= maxVolumes
        ? maxVolumes
        : currentVolumes + 1;
    if (nextVolumes == currentVolumes) return;

    final nowTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _updateEntryOptimistically(
      entryId: entryId,
      transform: (entry) {
        entry['progressVolumes'] = nextVolumes;
        entry['updatedAt'] = nowTimestamp;
        return entry;
      },
      request: () => _repo.saveMediaListEntry(
        id: entryId,
        mediaId: mediaId,
        progressVolumes: nextVolumes,
      ),
    );
  }

  /// Updates personal score with instant optimistic UI update
  Future<void> updateScore({
    required int entryId,
    required int mediaId,
    required double score,
  }) async {
    final nowTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _updateEntryOptimistically(
      entryId: entryId,
      transform: (entry) {
        entry['score'] = score;
        entry['updatedAt'] = nowTimestamp;
        return entry;
      },
      request: () => _repo.saveMediaListEntry(
        id: entryId,
        mediaId: mediaId,
        score: score,
      ),
    );
  }
}
