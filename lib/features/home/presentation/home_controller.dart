import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';

final homeDataProvider =
    StateNotifierProvider<HomeController, AsyncValue<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  return HomeController(repo);
});

class HomeController extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final HomeRepository _repo;

  HomeController(this._repo) : super(const AsyncValue.loading()) {
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.fetchHomeData();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final data = await _repo.fetchHomeData();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
