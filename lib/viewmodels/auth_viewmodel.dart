import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

export '../services/auth_service.dart'
    show authServiceProvider, authStateProvider, currentUserUidProvider, currentUserEmailProvider;

class RegisterNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final DatabaseService _db;

  RegisterNotifier(this._authService, this._db) : super(const AsyncValue.data(null));

  Future<bool> register({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final uid = await _authService.registerWithEmail(email: email, password: password);
      // Sign out immediately before Firebase auth stream emits the new user
      await _authService.signOut();
      await _db.insertLocalUser(UserProfile(
        uid: uid,
        email: email,
        createdAt: DateTime.now(),
      ));
      state = const AsyncValue.data(null);
      return true;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return false;
    }
  }
}

final registerProvider = StateNotifierProvider<RegisterNotifier, AsyncValue<void>>((ref) {
  return RegisterNotifier(
    ref.watch(authServiceProvider),
    ref.watch(databaseServiceProvider),
  );
});

final signOutProvider = Provider((ref) {
  final auth = ref.read(authServiceProvider);
  return () async => auth.signOut();
});

// Ensures user exists in local SQLite on every login
final ensureLocalUserProvider = Provider((ref) {
  final db = ref.read(databaseServiceProvider);
  return (String uid, String email) async {
    final existing = await db.getLocalUser(uid);
    if (existing == null) {
      await db.insertLocalUser(UserProfile(
        uid: uid,
        email: email,
        createdAt: DateTime.now(),
      ));
    }
  };
});
