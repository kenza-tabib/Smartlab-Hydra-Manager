import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

/// Immutable state held by the AuthNotifier.
class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.role == 'Administrateur';

  AuthState copyWith({
    User? currentUser,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for the AuthService dependency (makes it easy to mock/override).
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// The Notifier itself.
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    Future.microtask(checkSession);
    return const AuthState();
  }

  Future<void> checkSession() async {
    state = state.copyWith(isLoading: true);

    final user = await _authService.getCurrentUser();

    state = state.copyWith(
      currentUser: user,
      isLoading: false,
      clearUser: user == null,
    );
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authService.login(username, password);
      if (user != null) {
        state = state.copyWith(
          currentUser: user,
          isLoading: false,
          clearError: true,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Identifiants incorrects',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de connexion',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = state.copyWith(clearUser: true, clearError: true);
  }
}

/// The provider to use in widgets: ref.watch(authProvider) / ref.read(authProvider.notifier)
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});