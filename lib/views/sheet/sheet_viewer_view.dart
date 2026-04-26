import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sheet_music.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/sheet_viewer_viewmodel.dart';
import '../sheet/edit_metadata_view.dart';

class SheetViewerScreen extends ConsumerStatefulWidget {
  const SheetViewerScreen({super.key, required this.sheet});
  final SheetMusic sheet;

  @override
  ConsumerState<SheetViewerScreen> createState() => _SheetViewerScreenState();
}

class _SheetViewerScreenState extends ConsumerState<SheetViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  double _speedMultiplier = 20.0;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _scrollTimer?.cancel();
    const dt = Duration(milliseconds: 16);
    final pixelsPerFrame = _speedMultiplier * (dt.inMilliseconds / 1000.0);

    _scrollTimer = Timer.periodic(dt, (_) {
      if (!_scrollController.hasClients) return;
      final newOffset = _scrollController.offset + pixelsPerFrame;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (newOffset >= maxScroll) {
        _scrollController.jumpTo(maxScroll);
        ref.read(sheetViewerViewModelProvider.notifier).stopAndReset();
      } else {
        _scrollController.jumpTo(newOffset);
      }
    });
  }

  void _stopTimer() => _scrollTimer?.cancel();

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(builder: (_) => EditMetadataScreen(existingSheet: widget.sheet)),
    );
    if (updated == true && mounted) {
      ref.read(homeViewModelProvider.notifier).loadAllSheetMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(sheetViewerViewModelProvider);

    ref.listen<SheetViewerState>(sheetViewerViewModelProvider, (prev, next) {
      if (next.isPlaying && next.autoscrollEnabled) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF111318),
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.sheet.title, style: const TextStyle(color: CupertinoColors.white)),
        backgroundColor: const Color(0xFF111318),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: _openEdit,
          child: const Icon(CupertinoIcons.pencil, color: CupertinoColors.white, size: 20),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    ...widget.sheet.imagePath
                        .split(',')
                        .where((p) => p.trim().isNotEmpty)
                        .map((path) => Image.file(File(path), width: double.infinity, fit: BoxFit.fitWidth)),
                    const SizedBox(height: 160),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _ControlPanel(
                vm: vm,
                speedMultiplier: _speedMultiplier,
                onSpeedChanged: (val) {
                  setState(() => _speedMultiplier = val);
                  if (vm.isPlaying) _startTimer();
                },
                onTogglePlay: () => ref.read(sheetViewerViewModelProvider.notifier).togglePlay(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.vm,
    required this.speedMultiplier,
    required this.onSpeedChanged,
    required this.onTogglePlay,
  });

  final SheetViewerState vm;
  final double speedMultiplier;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2028),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33888888)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.4), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speed  ${speedMultiplier.toInt()}',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                CupertinoSlider(
                  value: speedMultiplier,
                  min: 5.0,
                  max: 100.0,
                  onChanged: onSpeedChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                onPressed: onTogglePlay,
                color: vm.isPlaying ? CupertinoColors.systemOrange : primary,
                borderRadius: BorderRadius.circular(13),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      vm.isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                      color: CupertinoColors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vm.isPlaying ? 'PAUSE AUTO-SCROLL' : 'START AUTO-SCROLL',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.3,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
