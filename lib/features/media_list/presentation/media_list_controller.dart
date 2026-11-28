import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/media_progress_util.dart';
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
    String? moveToStatus,
  }) async {
    final previousState = state;
    if (state.hasValue) {
      Map<String, dynamic>? movedEntry;
      final updatedLists = <Map<String, dynamic>>[];

      for (final group in state.value!) {
        final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>();
        if (entries == null) {
          updatedLists.add(group);
          continue;
        }

        final groupStatus = (group['status'] as String?)?.toUpperCase();
        var groupModified = false;
        final updatedEntries = <Map<String, dynamic>>[];

        for (final entry in entries) {
          if (entry['id'] != entryId) {
            updatedEntries.add(entry);
            continue;
          }
          groupModified = true;
          final transformed = transform(Map<String, dynamic>.from(entry));
          if (moveToStatus != null && groupStatus != moveToStatus.toUpperCase()) {
            movedEntry = transformed;
          } else {
            updatedEntries.add(transformed);
          }
        }

        if (groupModified) {
          updatedLists.add({
            ...group,
            'entries': updatedEntries,
          });
        } else {
          updatedLists.add(group);
        }
      }

      if (movedEntry != null && moveToStatus != null) {
        final targetUpper = moveToStatus.toUpperCase();
        var targetIndex = updatedLists.indexWhere(
          (g) => (g['status'] as String?)?.toUpperCase() == targetUpper,
        );
        if (targetIndex != -1) {
          final targetGroup = updatedLists[targetIndex];
          final existing = (targetGroup['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          updatedLists[targetIndex] = {
            ...targetGroup,
            'entries': [movedEntry, ...existing],
          };
        } else {
          updatedLists.add({
            'name': _defaultGroupName(targetUpper),
            'isCustomList': false,
            'status': targetUpper,
            'entries': [movedEntry],
          });
        }
      }

      state = AsyncValue.data(updatedLists);
    }

    try {
      await request();
    } catch (_) {
      state = previousState;
    }
  }

  String _defaultGroupName(String statusUpper) {
    final isManga = _type == 'MANGA';
    switch (statusUpper) {
      case 'CURRENT':
        return isManga ? 'Reading' : 'Watching';
      case 'REPEATING':
        return isManga ? 'Rereading' : 'Rewatching';
      case 'COMPLETED':
        return 'Completed';
      case 'PLANNING':
        return 'Planning';
      case 'PAUSED':
        return 'Paused';
      case 'DROPPED':
        return 'Dropped';
      default:
        return statusUpper;
    }
  }

  Map<String, dynamic>? _findEntryById(int entryId) {
    final lists = state.valueOrNull;
    if (lists == null) return null;
    for (final group in lists) {
      final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final entry in entries) {
        if (entry['id'] == entryId) return entry;
      }
    }
    return null;
  }

  /// Increments progress by 1 with instant optimistic UI update.
  /// Handles start/finish date auto-fill, status promotion (`PLANNING -> CURRENT`),
  /// manga volume completion sync, and `REPEATING -> COMPLETED` repeat bumps.
  Future<void> incrementProgress({
    required int entryId,
    required int mediaId,
    required int currentProgress,
    int? maxEpisodesOrChapters,
    int? maxVolumes,
    String? currentStatus,
    int? currentRepeat,
  }) async {
    if (maxEpisodesOrChapters != null && currentProgress >= maxEpisodesOrChapters) return;

    final existing = _findEntryById(entryId);
    final prevStatus =
        (currentStatus ?? existing?['status'] as String?)?.toUpperCase() ?? 'CURRENT';
    final prevRepeat = currentRepeat ?? (existing?['repeat'] as int? ?? 0);
    final prevVolumes = existing?['progressVolumes'] as int? ?? 0;
    final resolvedMaxVolumes =
        maxVolumes ?? (existing?['media'] as Map<String, dynamic>?)?['volumes'] as int?;

    final res = MediaProgressUtil.resolveQuickIncrement(
      currentStatus: prevStatus,
      currentProgress: currentProgress,
      currentVolumes: prevVolumes,
      currentRepeat: prevRepeat,
      maxCount: maxEpisodesOrChapters,
      maxVolumes: resolvedMaxVolumes,
      existingStartedAt: existing?['startedAt'],
      existingCompletedAt: existing?['completedAt'],
      isManga: _type == 'MANGA',
    );
    final nowTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _updateEntryOptimistically(
      entryId: entryId,
      moveToStatus: res.statusChanged ? res.status : null,
      transform: (entry) {
        entry['progress'] = res.progress;
        entry['updatedAt'] = nowTimestamp;
        if (res.statusChanged) {
          entry['status'] = res.status;
        }
        if (res.repeatChanged) {
          entry['repeat'] = res.repeat;
        }
        if (res.volumesChanged) {
          entry['progressVolumes'] = res.progressVolumes;
        }
        if (res.startedAtChanged && res.startedAt != null) {
          entry['startedAt'] = res.startedAt;
        }
        if (res.completedAtChanged && res.completedAt != null) {
          entry['completedAt'] = res.completedAt;
        }
        return entry;
      },
      request: () => _repo.saveMediaListEntry(
        id: entryId,
        mediaId: mediaId,
        progress: res.progress,
        progressVolumes: res.volumesChanged ? res.progressVolumes : null,
        status: res.statusChanged ? res.status : null,
        repeat: res.repeatChanged ? res.repeat : null,
        startedAt: res.startedAtChanged ? res.startedAt : null,
        completedAt: res.completedAtChanged ? res.completedAt : null,
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
    if (maxVolumes != null && currentVolumes >= maxVolumes) return;
    final existing = _findEntryById(entryId);
    final res = MediaProgressUtil.resolveQuickVolumeIncrement(
      currentStatus: existing?['status'] as String?,
      currentVolumes: currentVolumes,
      maxVolumes: maxVolumes,
      existingStartedAt: existing?['startedAt'],
    );
    if (res.progressVolumes == currentVolumes) return;

    final nowTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _updateEntryOptimistically(
      entryId: entryId,
      moveToStatus: res.statusChanged ? res.status : null,
      transform: (entry) {
        entry['progressVolumes'] = res.progressVolumes;
        entry['updatedAt'] = nowTimestamp;
        if (res.statusChanged) {
          entry['status'] = res.status;
        }
        if (res.startedAtChanged && res.startedAt != null) {
          entry['startedAt'] = res.startedAt;
        }
        return entry;
      },
      request: () => _repo.saveMediaListEntry(
        id: entryId,
        mediaId: mediaId,
        progressVolumes: res.progressVolumes,
        status: res.statusChanged ? res.status : null,
        startedAt: res.startedAtChanged ? res.startedAt : null,
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
