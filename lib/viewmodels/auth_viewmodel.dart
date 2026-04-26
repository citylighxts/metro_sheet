import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

export '../services/auth_service.dart'
    show authServiceProvider, authStateProvider, currentUserUidProvider, currentUserEmailProvider;

class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  LoginNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _authService.loginWithEmail(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, AsyncValue<void>>((ref) {
  return LoginNotifier(ref.watch(authServiceProvider));
});

class RegisterNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  RegisterNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<bool> register({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _authService.registerWithEmail(email: email, password: password);
      await _authService.signOut();
      state = const AsyncValue.data(null);
      return true;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return false;
    }
  }
}

final registerProvider = StateNotifierProvider<RegisterNotifier, AsyncValue<void>>((ref) {
  return RegisterNotifier(ref.watch(authServiceProvider));
});

final signOutProvider = Provider((ref) {
  final auth = ref.read(authServiceProvider);
  return () async => auth.signOut();
});
