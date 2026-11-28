import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/settings/content_settings_provider.dart';
import '../../media_list/presentation/media_list_controller.dart';
import '../data/home_repository.dart';

final homeDataProvider =
    StateNotifierProvider<HomeController, AsyncValue<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  final includeAdult = ref.watch(adultContentProvider);
  final controller = HomeController(repo, includeAdult: includeAdult);

  void syncFromLists(AsyncValue<List<Map<String, dynamic>>> listState) {
    listState.whenData((lists) {
      controller.updateMediaIds(_extractPrioritizedIds(lists));
    });
  }

  // Initial sync if anime list is already available (e.g. tab switch), otherwise wait cleanly for first load
  syncFromLists(ref.read(animeListControllerProvider));

  ref.listen<AsyncValue<List<Map<String, dynamic>>>>(
    animeListControllerProvider,
    (_, next) => syncFromLists(next),
  );

  return controller;
});

List<int> _extractPrioritizedIds(List<Map<String, dynamic>> animeLists) {
  final prioritizedIds = <int>{};
  const priorityStatuses = ['CURRENT', 'REPEATING', 'PLANNING', 'PAUSED'];
  for (final targetStatus in priorityStatuses) {
    for (final group in animeLists) {
      if ((group['status'] as String?)?.toUpperCase() != targetStatus) continue;
      final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final e in entries) {
        final mid = e['media']?['id'] as int?;
        if (mid != null) prioritizedIds.add(mid);
      }
    }
  }
  return prioritizedIds.toList();
}

class HomeController extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final HomeRepository _repo;
  final bool _includeAdult;
  List<int>? _lastMediaIds;
  bool _isFetching = false;

  HomeController(this._repo, {bool includeAdult = false})
      : _includeAdult = includeAdult,
        super(const AsyncValue.loading());

  Future<void> updateMediaIds(List<int> mediaIds) async {
    if (_lastMediaIds != null && listEquals(_lastMediaIds, mediaIds)) {
      return;
    }
    _lastMediaIds = List<int>.from(mediaIds);
    await _fetch(showLoading: !state.hasValue);
  }

  Future<void> refresh() async {
    await _fetch(showLoading: false);
  }

  Future<void> _fetch({required bool showLoading}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (showLoading) {
      state = const AsyncValue.loading();
    }
    try {
      final data = await _repo.fetchHomeData(
        mediaIds: _lastMediaIds ?? const [],
        includeAdult: _includeAdult,
      );
      if (mounted) {
        state = AsyncValue.data(data);
      }
    } catch (e, st) {
      if (mounted && !state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isFetching = false;
    }
  }
}
