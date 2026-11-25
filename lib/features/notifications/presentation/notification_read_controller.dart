import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/notifications_repository.dart';

/// Immutable snapshot of notification unread state.
///
/// AniList does not store per-notification read flags in its GraphQL API; it
/// only exposes `Viewer.unreadNotificationCount` (`N` newest notifications)
/// and `notifications(resetNotificationCount: true)`. We pair that server
/// baseline with persisted local [readIds] and [forcedUnreadIds] so users can
/// inspect unread items before resetting the server counter and mark any item
/// read or unread individually.
@immutable
class NotificationReadState {
  final int serverUnreadCount;
  final Set<int> readIds;
  final Set<int> forcedUnreadIds;
  final List<int> loadedIds;

  const NotificationReadState({
    this.serverUnreadCount = 0,
    this.readIds = const {},
    this.forcedUnreadIds = const {},
    this.loadedIds = const [],
  });

  /// Returns whether notification at [index] (newest-first) with [id] is unread.
  bool isUnread(int index, int id) {
    if (forcedUnreadIds.contains(id)) return true;
    if (readIds.contains(id)) return false;
    return index >= 0 && index < serverUnreadCount;
  }

  /// Effective unread count displayed on badges and Unread filter chips.
  int get unreadCount {
    if (loadedIds.isEmpty) {
      return serverUnreadCount + forcedUnreadIds.length;
    }

    int count = 0;
    for (int i = 0; i < loadedIds.length; i++) {
      if (isUnread(i, loadedIds[i])) count++;
    }

    // Account for any server-unread notifications beyond loaded pages.
    if (serverUnreadCount > loadedIds.length) {
      count += serverUnreadCount - loadedIds.length;
    }

    // Account for any forcedUnreadIds not currently in [loadedIds].
    for (final id in forcedUnreadIds) {
      if (!loadedIds.contains(id)) count++;
    }

    return count;
  }

  NotificationReadState copyWith({
    int? serverUnreadCount,
    Set<int>? readIds,
    Set<int>? forcedUnreadIds,
    List<int>? loadedIds,
  }) {
    return NotificationReadState(
      serverUnreadCount: serverUnreadCount ?? this.serverUnreadCount,
      readIds: readIds ?? this.readIds,
      forcedUnreadIds: forcedUnreadIds ?? this.forcedUnreadIds,
      loadedIds: loadedIds ?? this.loadedIds,
    );
  }
}

final notificationReadProvider =
    StateNotifierProvider<NotificationReadNotifier, NotificationReadState>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final repo = ref.watch(notificationsRepositoryProvider);
  final notifier = NotificationReadNotifier(storage, repo);

  final authState = ref.watch(authControllerProvider);
  if (authState is Authenticated) {
    notifier.syncServerCount(authState.user.unreadNotificationCount);
  } else if (authState is Unauthenticated || authState is GuestMode) {
    notifier.clearForLoggedOut();
  }

  return notifier;
});

class NotificationReadNotifier extends StateNotifier<NotificationReadState> {
  final LocalStorageService _storage;
  final NotificationsRepository _repo;
  int? _lastSyncedServerCount;

  NotificationReadNotifier(this._storage, this._repo)
      : super(
          NotificationReadState(
            readIds: _storage.getIntIdSet(LocalStorageService.keyReadNotificationIds),
            forcedUnreadIds:
                _storage.getIntIdSet(LocalStorageService.keyForcedUnreadNotificationIds),
            loadedIds: _storage.getIntIdList(LocalStorageService.keyLastNotificationIds),
          ),
        );

  void syncServerCount(int count) {
    final safeCount = count < 0 ? 0 : count;
    // If new unread notifications arrived on server since last loaded snapshot,
    // clear cached order so top indices don't hide brand-new items.
    final prev = _lastSyncedServerCount;
    _lastSyncedServerCount = safeCount;
    final shouldDropStaleOrder = prev != null && safeCount > prev;
    state = state.copyWith(
      serverUnreadCount: safeCount,
      loadedIds: shouldDropStaleOrder ? const [] : null,
    );
  }

  void clearForLoggedOut() {
    _lastSyncedServerCount = null;
    state = const NotificationReadState();
  }

  Future<void> refreshFromServer() async {
    try {
      final count = await _repo.fetchUnreadCount();
      if (!mounted) return;
      syncServerCount(count);
    } catch (_) {}
  }

  Future<void> setLoadedNotificationIds(List<int> ids) async {
    state = state.copyWith(loadedIds: List<int>.unmodifiable(ids));
    await _storage.setIntIdList(LocalStorageService.keyLastNotificationIds, ids);
  }

  Future<void> markRead(int id) async {
    final nextRead = Set<int>.from(state.readIds)..add(id);
    final nextForcedUnread = Set<int>.from(state.forcedUnreadIds)..remove(id);
    state = state.copyWith(
      readIds: nextRead,
      forcedUnreadIds: nextForcedUnread,
    );
    await _persistReadSets(nextRead, nextForcedUnread);

    // If all server-unread items have now been read locally, clear server badge too.
    if (state.unreadCount == 0 && state.serverUnreadCount > 0) {
      await _resetServerCounterQuietly();
    }
  }

  Future<void> markUnread(int id) async {
    final nextRead = Set<int>.from(state.readIds)..remove(id);
    final nextForcedUnread = Set<int>.from(state.forcedUnreadIds)..add(id);
    state = state.copyWith(
      readIds: nextRead,
      forcedUnreadIds: nextForcedUnread,
    );
    await _persistReadSets(nextRead, nextForcedUnread);
  }

  Future<void> toggleReadUnread(int index, int id) async {
    if (state.isUnread(index, id)) {
      await markRead(id);
    } else {
      await markUnread(id);
    }
  }

  Future<void> markAllRead() async {
    final nextRead = Set<int>.from(state.readIds)..addAll(state.loadedIds);
    state = state.copyWith(
      serverUnreadCount: 0,
      readIds: nextRead,
      forcedUnreadIds: const {},
    );
    _lastSyncedServerCount = 0;
    await _persistReadSets(nextRead, const {});
    await _resetServerCounterQuietly();
  }

  Future<void> _resetServerCounterQuietly() async {
    state = state.copyWith(serverUnreadCount: 0);
    _lastSyncedServerCount = 0;
    try {
      await _repo.resetServerUnreadCount();
    } catch (_) {}
  }

  Future<void> _persistReadSets(Set<int> readIds, Set<int> forcedUnreadIds) async {
    await Future.wait([
      _storage.setIntIdSet(LocalStorageService.keyReadNotificationIds, readIds),
      _storage.setIntIdSet(
        LocalStorageService.keyForcedUnreadNotificationIds,
        forcedUnreadIds,
      ),
    ]);
  }
}
