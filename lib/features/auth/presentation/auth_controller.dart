import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/models/user_model.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  Authenticated(this.user);
}

class GuestMode extends AuthState {}

class Unauthenticated extends AuthState {
  final String? error;
  Unauthenticated([this.error]);
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(AuthInitial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = AuthLoading();
    try {
      if (_repo.isGuest) {
        state = GuestMode();
        return;
      }

      final hasToken = await _repo.hasToken();
      if (!hasToken) {
        state = Unauthenticated();
        return;
      }

      final user = await _repo.getViewer();
      state = Authenticated(user);
    } catch (e) {
      // If fetching user profile fails due to expired token
      await _repo.clearAuth();
      state = Unauthenticated(e.toString());
    }
  }

  Future<void> loginWithToken(String token) async {
    state = AuthLoading();
    try {
      await _repo.saveToken(token.trim());
      final user = await _repo.getViewer();
      state = Authenticated(user);
    } catch (e) {
      await _repo.clearAuth();
      state = Unauthenticated('Failed to authenticate: $e');
    }
  }

  void loginAsGuest() {
    _repo.loginAsGuest();
    state = GuestMode();
  }

  Future<void> logout() async {
    state = AuthLoading();
    await _repo.clearAuth();
    state = Unauthenticated();
  }
}
