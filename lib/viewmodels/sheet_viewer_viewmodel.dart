import 'package:flutter_riverpod/flutter_riverpod.dart';

class SheetViewerState {
  final bool isPlaying;
  final bool autoscrollEnabled;

  const SheetViewerState({
    required this.isPlaying,
    required this.autoscrollEnabled,
  });

  SheetViewerState copyWith({bool? isPlaying, bool? autoscrollEnabled}) {
    return SheetViewerState(
      isPlaying: isPlaying ?? this.isPlaying,
      autoscrollEnabled: autoscrollEnabled ?? this.autoscrollEnabled,
    );
  }
}

class SheetViewerViewModel extends StateNotifier<SheetViewerState> {
  SheetViewerViewModel()
      : super(const SheetViewerState(isPlaying: false, autoscrollEnabled: false));

  void togglePlay() {
    final nowPlaying = !state.isPlaying;
    state = state.copyWith(
      isPlaying: nowPlaying,
      autoscrollEnabled: nowPlaying ? true : state.autoscrollEnabled,
    );
  }

  void stopAndReset() {
    state = const SheetViewerState(isPlaying: false, autoscrollEnabled: false);
  }
}

final sheetViewerViewModelProvider =
    StateNotifierProvider.autoDispose<SheetViewerViewModel, SheetViewerState>(
  (ref) => SheetViewerViewModel(),
);
