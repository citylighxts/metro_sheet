import 'package:flutter_riverpod/flutter_riverpod.dart';

class SheetViewerState {
  final int bpm;
  final bool isPlaying;
  final bool autoscrollEnabled;

  const SheetViewerState({
    required this.bpm,
    required this.isPlaying,
    required this.autoscrollEnabled,
  });

  SheetViewerState copyWith({int? bpm, bool? isPlaying, bool? autoscrollEnabled}) {
    return SheetViewerState(
      bpm: bpm ?? this.bpm,
      isPlaying: isPlaying ?? this.isPlaying,
      autoscrollEnabled: autoscrollEnabled ?? this.autoscrollEnabled,
    );
  }
}

class SheetViewerViewModel extends StateNotifier<SheetViewerState> {
  SheetViewerViewModel(int initialBpm)
      : super(SheetViewerState(bpm: initialBpm, isPlaying: false, autoscrollEnabled: false));

  void setBpm(int bpm) => state = state.copyWith(bpm: bpm.clamp(20, 300));
  void incrementBpm() => setBpm(state.bpm + 1);
  void decrementBpm() => setBpm(state.bpm - 1);

  void togglePlay() {
    final nowPlaying = !state.isPlaying;
    state = state.copyWith(
      isPlaying: nowPlaying,
      autoscrollEnabled: nowPlaying ? true : state.autoscrollEnabled,
    );
  }

  void stopAndReset() {
    state = state.copyWith(isPlaying: false, autoscrollEnabled: false);
  }
}

final sheetViewerViewModelProvider =
    StateNotifierProvider.autoDispose<SheetViewerViewModel, SheetViewerState>(
  (ref) => SheetViewerViewModel(120),
);
