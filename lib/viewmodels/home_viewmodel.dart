import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sheet_music.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

export '../services/auth_service.dart'
    show authServiceProvider, authStateProvider, currentUserUidProvider, currentUserEmailProvider;

final sheetMusicServiceProvider = Provider((ref) => DatabaseService());

class HomeViewModel extends StateNotifier<AsyncValue<List<SheetMusic>>> {
  final DatabaseService _db;
  final String? _uid;

  HomeViewModel(this._db, this._uid) : super(const AsyncValue.loading());

  Future<void> loadAllSheetMusic() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _db.getAllSheetMusic());
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<int?> addSheetMusic(SheetMusic sheetMusic) async {
    try {
      final id = await _db.addSheetMusic(sheetMusic, _uid);
      await loadAllSheetMusic();
      return id;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return null;
    }
  }

  Future<bool> updateSheetMusic(SheetMusic sheetMusic) async {
    try {
      await _db.updateSheetMusic(sheetMusic);
      await loadAllSheetMusic();
      return true;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return false;
    }
  }

  Future<bool> deleteSheetMusic(SheetMusic sheetMusic) async {
    if (sheetMusic.id == null) return false;
    final prev = state;
    if (prev is AsyncData<List<SheetMusic>>) {
      state = AsyncValue.data(prev.value.where((s) => s.id != sheetMusic.id).toList());
    }
    try {
      await _db.deleteSheetMusic(sheetMusic.id!, sheetMusic.createdAt, _uid);
      return true;
    } catch (_) {
      state = prev;
      return false;
    }
  }
}

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, AsyncValue<List<SheetMusic>>>((ref) {
  final db = ref.watch(sheetMusicServiceProvider);
  final uid = ref.watch(currentUserUidProvider);
  final notifier = HomeViewModel(db, uid);
  notifier.loadAllSheetMusic();
  return notifier;
});

final sheetMusicCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(sheetMusicServiceProvider).getSheetMusicCount();
});
