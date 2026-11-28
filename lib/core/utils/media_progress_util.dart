/// Pure status-transition and progress-increment guards shared across
/// MediaEditor, Shelves, MediaList, and MediaDetail screens.
class MediaStatusTransitionResult {
  final String status;
  final int progress;
  final int progressVolumes;
  final int repeat;
  final Map<String, int>? startedAt;
  final Map<String, int>? completedAt;
  final bool repeatIncremented;

  const MediaStatusTransitionResult({
    required this.status,
    required this.progress,
    required this.progressVolumes,
    required this.repeat,
    required this.startedAt,
    required this.completedAt,
    this.repeatIncremented = false,
  });
}

class MediaQuickIncrementResult {
  final String status;
  final int progress;
  final int progressVolumes;
  final int repeat;
  final Map<String, int>? startedAt;
  final Map<String, int>? completedAt;
  final bool statusChanged;
  final bool volumesChanged;
  final bool repeatChanged;
  final bool startedAtChanged;
  final bool completedAtChanged;
  final bool isCompleted;

  const MediaQuickIncrementResult({
    required this.status,
    required this.progress,
    required this.progressVolumes,
    required this.repeat,
    required this.startedAt,
    required this.completedAt,
    required this.statusChanged,
    required this.volumesChanged,
    required this.repeatChanged,
    required this.startedAtChanged,
    required this.completedAtChanged,
    required this.isCompleted,
  });
}

class MediaQuickVolumeResult {
  final String status;
  final int progressVolumes;
  final Map<String, int>? startedAt;
  final bool statusChanged;
  final bool startedAtChanged;

  const MediaQuickVolumeResult({
    required this.status,
    required this.progressVolumes,
    required this.startedAt,
    required this.statusChanged,
    required this.startedAtChanged,
  });
}

class MediaProgressUtil {
  MediaProgressUtil._();

  /// Safely parses an AniList FuzzyDate map. Returns null when unset or when
  /// AniList returns `{year: null, month: null, day: null}`.
  static Map<String, int>? parseFuzzyDate(dynamic raw) {
    if (raw is! Map) return null;
    final y = raw['year'];
    if (y is! int) return null;
    final m = raw['month'];
    final d = raw['day'];
    return {
      'year': y,
      if (m is int) 'month': m,
      if (d is int) 'day': d,
    };
  }

  /// Whether [raw] represents a populated fuzzy date with at least a year.
  static bool hasFuzzyDate(dynamic raw) => parseFuzzyDate(raw) != null;

  /// Today's local date in AniList `FuzzyDateInput` shape.
  static Map<String, int> todayFuzzyDate([DateTime? now]) {
    final d = now ?? DateTime.now();
    return {'year': d.year, 'month': d.month, 'day': d.day};
  }

  static bool _isPassiveStatus(String statusUpper) =>
      statusUpper == 'PLANNING' || statusUpper == 'PAUSED' || statusUpper == 'DROPPED';

  /// Computes updated progress, volumes, repeat count, and dates when changing
  /// an entry's status (for example `COMPLETED -> REPEATING` or `REPEATING -> COMPLETED`).
  static MediaStatusTransitionResult resolveStatusChange({
    required String previousStatus,
    required String nextStatus,
    required int currentProgress,
    required int currentVolumes,
    required int currentRepeat,
    int? maxCount,
    int? maxVolumes,
    dynamic startedAt,
    dynamic completedAt,
    required bool isManga,
    bool hasIncrementedRepeatThisSession = false,
    bool isNewEntry = false,
    DateTime? now,
  }) {
    final prev = previousStatus.toUpperCase();
    final next = nextStatus.toUpperCase();
    final today = todayFuzzyDate(now);

    var progress = currentProgress;
    var volumes = currentVolumes;
    var repeat = currentRepeat;
    var start = parseFuzzyDate(startedAt);
    var complete = parseFuzzyDate(completedAt);
    var repeatIncremented = false;

    if (prev == 'COMPLETED' && next == 'REPEATING') {
      // Starting a fresh rewatch/reread clears current pass counters while keeping
      // the prior dates and completed repeat count intact.
      progress = 0;
      if (isManga) volumes = 0;
    } else if (next == 'COMPLETED') {
      if (maxCount != null) progress = maxCount;
      if (isManga && maxVolumes != null) volumes = maxVolumes;
      // Completing a rewatch/reread updates Finish Date to today immediately;
      // normal completion fills Finish Date whenever it wasn't manually set yet.
      complete = prev == 'REPEATING' ? today : (complete ?? today);
      if (prev == 'REPEATING' && !hasIncrementedRepeatThisSession) {
        repeat = currentRepeat + 1;
        repeatIncremented = true;
      }
      if (start == null && (maxCount == 1 || currentProgress == 0)) {
        start = today;
      }
    } else if (next == 'CURRENT') {
      start ??= today;
    } else if (next == 'PLANNING' && isNewEntry) {
      start = null;
    }

    return MediaStatusTransitionResult(
      status: next,
      progress: progress,
      progressVolumes: volumes,
      repeat: repeat,
      startedAt: start,
      completedAt: complete,
      repeatIncremented: repeatIncremented,
    );
  }

  /// Single source of truth for `+1 Ep` / `+1 Ch` quick increments across
  /// Home shelves, MediaList, and MediaDetail screens.
  static MediaQuickIncrementResult resolveQuickIncrement({
    required String? currentStatus,
    required int currentProgress,
    int currentVolumes = 0,
    int currentRepeat = 0,
    int? maxCount,
    int? maxVolumes,
    dynamic existingStartedAt,
    dynamic existingCompletedAt,
    required bool isManga,
    DateTime? now,
  }) {
    final prevStatus = (currentStatus ?? 'CURRENT').toUpperCase();
    final today = todayFuzzyDate(now);
    final nextProgress = currentProgress + 1;
    final isNowCompleted = maxCount != null && nextProgress >= maxCount;

    final nextStatus = isNowCompleted
        ? 'COMPLETED'
        : (_isPassiveStatus(prevStatus) ? 'CURRENT' : prevStatus);
    final statusChanged = nextStatus != prevStatus;

    final repeatChanged = isNowCompleted && prevStatus == 'REPEATING';
    final nextRepeat = repeatChanged ? currentRepeat + 1 : currentRepeat;

    final volumesChanged =
        isManga && isNowCompleted && maxVolumes != null && currentVolumes < maxVolumes;
    final nextVolumes = volumesChanged ? maxVolumes : currentVolumes;

    final parsedStart = parseFuzzyDate(existingStartedAt);
    final parsedComplete = parseFuzzyDate(existingCompletedAt);

    final startedAtChanged =
        parsedStart == null && (currentProgress == 0 || (isNowCompleted && maxCount == 1));
    final nextStart = startedAtChanged ? today : parsedStart;

    final completedAtChanged =
        isNowCompleted && (prevStatus == 'REPEATING' || parsedComplete == null);
    final nextComplete = completedAtChanged ? today : parsedComplete;

    return MediaQuickIncrementResult(
      status: nextStatus,
      progress: nextProgress,
      progressVolumes: nextVolumes,
      repeat: nextRepeat,
      startedAt: nextStart,
      completedAt: nextComplete,
      statusChanged: statusChanged,
      volumesChanged: volumesChanged,
      repeatChanged: repeatChanged,
      startedAtChanged: startedAtChanged,
      completedAtChanged: completedAtChanged,
      isCompleted: isNowCompleted,
    );
  }

  /// Resolves `+1 Vol` quick increment for Manga entries, promoting passive
  /// statuses (`PLANNING`, `PAUSED`, `DROPPED`) to `CURRENT` and setting Start Date.
  static MediaQuickVolumeResult resolveQuickVolumeIncrement({
    required String? currentStatus,
    required int currentVolumes,
    int? maxVolumes,
    dynamic existingStartedAt,
    DateTime? now,
  }) {
    final prevStatus = (currentStatus ?? 'CURRENT').toUpperCase();
    final today = todayFuzzyDate(now);
    final nextVolumes = (maxVolumes != null && currentVolumes >= maxVolumes)
        ? maxVolumes
        : currentVolumes + 1;
    final promoted = _isPassiveStatus(prevStatus);
    final nextStatus = promoted ? 'CURRENT' : prevStatus;
    final parsedStart = parseFuzzyDate(existingStartedAt);
    final startedAtChanged = parsedStart == null && (currentVolumes == 0 || promoted);
    final nextStart = startedAtChanged ? today : parsedStart;

    return MediaQuickVolumeResult(
      status: nextStatus,
      progressVolumes: nextVolumes,
      startedAt: nextStart,
      statusChanged: nextStatus != prevStatus,
      startedAtChanged: startedAtChanged,
    );
  }

  /// Returns the latest aired episode number from `nextAiringEpisode`, or null
  /// when the series is finished or lacks airing schedule metadata.
  static int? latestAiredEpisode(Map<String, dynamic> media) {
    final nextAiring = media['nextAiringEpisode'] as Map<String, dynamic>?;
    final nextEp = nextAiring?['episode'] as int?;
    if (nextEp == null) return null;
    return (nextEp - 1).clamp(0, 999999);
  }

  /// Whether a `+1` / `+Ch` quick-increment action should be shown for [media].
  static bool canIncrementProgress({
    required String? status,
    required int progress,
    required Map<String, dynamic> media,
  }) {
    if (status?.toUpperCase() == 'COMPLETED') return false;
    final isManga = media['type'] == 'MANGA' ||
        (media['episodes'] == null && media['chapters'] != null);
    final maxCount = (isManga ? media['chapters'] : media['episodes']) as int?;
    if (maxCount != null && progress >= maxCount) return false;

    if (!isManga) {
      final latestAired = latestAiredEpisode(media);
      if (latestAired != null && progress >= latestAired) return false;
    }
    return true;
  }

  /// Whether a `+Vol` quick-increment action should be shown for a manga entry.
  static bool canIncrementVolume({
    required String? status,
    required int progressVolumes,
    required Map<String, dynamic> media,
  }) {
    if (status?.toUpperCase() == 'COMPLETED') return false;
    final maxVols = media['volumes'] as int?;
    if (maxVols != null && progressVolumes >= maxVols) return false;
    return true;
  }
}
