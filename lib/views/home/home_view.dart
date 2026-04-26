import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/sheet_music_card.dart';
import '../../models/sheet_music.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/device_service.dart';
import '../sheet/edit_metadata_view.dart';
import '../sheet/sheet_viewer_view.dart';

const _kAccent = Color(0xFF1E5FA8);

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  bool _didAskNotificationPermission = false;
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didAskNotificationPermission) return;
    _didAskNotificationPermission = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestNotificationPermission());
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await ref.read(deviceServiceProvider).requestNotificationPermission();
    if (!mounted || granted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Izin notifikasi ditolak. Aktifkan lewat Settings iOS.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabBg = CupertinoColors.systemBackground.resolveFrom(context).withValues(alpha: 0.92);
    final separator = CupertinoColors.separator.resolveFrom(context);

    final tabs = [
      const _LibraryTab(),
      _SettingsTab(onLogout: () => _handleLogout(context)),
    ];

    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      body: tabs[_currentIndex],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: tabBg,
              border: Border(top: BorderSide(color: separator, width: 0.3)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      _TabItem(
                        icon: CupertinoIcons.music_note_list,
                        filledIcon: CupertinoIcons.music_note_list,
                        label: 'Library',
                        selected: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      const SizedBox(width: 80),
                      _TabItem(
                        icon: CupertinoIcons.settings,
                        filledIcon: CupertinoIcons.settings_solid,
                        label: 'Settings',
                        selected: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: () => _startScanFlow(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _kAccent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: _kAccent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: const SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(CupertinoIcons.viewfinder, color: CupertinoColors.white, size: 30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Scan', style: TextStyle(fontSize: 10, color: _kAccent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await _confirmLogout(context);
    if (!shouldLogout) return;
    await ref.read(signOutProvider)();
  }

  Future<void> _startScanFlow(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final deviceService = ref.read(deviceServiceProvider);

    final cameraGranted = await deviceService.ensureCameraPermission();
    if (!context.mounted) return;

    if (!cameraGranted) {
      messenger.showSnackBar(SnackBar(
        content: const Text('Izin kamera dibutuhkan untuk scan dokumen.'),
        action: SnackBarAction(label: 'Settings', onPressed: deviceService.openAppSettingsPage),
      ));
      return;
    }

    try {
      final rawPaths = await deviceService.scanDocumentRaw();
      if (!context.mounted) return;

      if (rawPaths == null || rawPaths.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('Scan dibatalkan.')));
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xCC1C1C1E),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(radius: 14, color: CupertinoColors.white),
                  SizedBox(height: 12),
                  Text('Saving...', style: TextStyle(color: CupertinoColors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      );

      final savedImagePath = await deviceService.saveScannedImages(rawPaths);
      if (!context.mounted) return;
      Navigator.of(context).pop();

      final isSaved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EditMetadataScreen(imagePath: savedImagePath)),
      ) ?? false;

      if (!context.mounted) return;

      if (isSaved) {
        ref.invalidate(sheetMusicCountProvider);
        ref.read(homeViewModelProvider.notifier).loadAllSheetMusic();
        messenger.showSnackBar(const SnackBar(content: Text('Sheet music berhasil disimpan.')));
      } else {
        await deviceService.deleteImage(savedImagePath);
        messenger.showSnackBar(const SnackBar(content: Text('Scan dibatalkan, file sementara dihapus.')));
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Gagal melakukan scan: $e')));
    }
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    return await showCupertinoModalPopup<bool>(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: const Text('Log Out?'),
            message: const Text('You will need to sign in again to access this account.'),
            actions: [
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Log Out'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
        ) ??
        false;
  }
}

class _LibraryTab extends ConsumerWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetMusicList = ref.watch(homeViewModelProvider);
    final sheetMusicCount = ref.watch(sheetMusicCountProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: MediaQuery.of(context).padding.copyWith(
              top: MediaQuery.of(context).padding.top - 40,
            ),
          ),
          child: CupertinoSliverNavigationBar(
            largeTitle: const Text('Library'),
            backgroundColor: _navBarColor(context),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: sheetMusicCount.when(
              data: (count) => Text(
                count == 0 ? 'No sheets yet' : '$count sheet${count == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
              ),
              loading: () => const SizedBox(height: 18, child: CupertinoActivityIndicator(radius: 8)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
        sheetMusicList.when(
          data: (sheets) => sheets.isEmpty
              ? const SliverFillRemaining(hasScrollBody: false, child: _EmptyLibrary())
              : SliverToBoxAdapter(child: _SheetMusicList(sheets: sheets)),
          loading: () => const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator())),
          error: (err, _) => SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Database Error: $err',
                    style: const TextStyle(color: CupertinoColors.destructiveRed),
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 96,
                height: 96,
                child: Icon(CupertinoIcons.doc_text_viewfinder, size: 48, color: _kAccent),
              ),
            ),
            const SizedBox(height: 20),
            const Text('No Sheet Music Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoColors.label)),
            const SizedBox(height: 8),
            const Text(
              'Tap Scan to add your first sheet music.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: CupertinoColors.secondaryLabel, height: 1.4),
            ),
          ],
        ),
      );
}

class _SheetMusicList extends ConsumerWidget {
  const _SheetMusicList({required this.sheets});
  final List<SheetMusic> sheets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(color: CupertinoColors.systemBackground.resolveFrom(context)),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: sheets.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 82,
              color: CupertinoColors.separator.resolveFrom(context),
            ),
            itemBuilder: (context, index) {
              final sheet = sheets[index];
              return SheetMusicCard(
                sheet: sheet,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => SheetViewerScreen(sheet: sheet)),
                ),
                onDelete: () => _deleteSheet(context, ref, sheet),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSheet(BuildContext context, WidgetRef ref, SheetMusic sheet) async {
    final confirmed = await _confirmDelete(context, sheet);
    if (!confirmed) return;
    try {
      final file = File(sheet.imagePath);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
    ref.read(homeViewModelProvider.notifier).deleteSheetMusic(sheet);
    ref.invalidate(sheetMusicCountProvider);
  }

  Future<bool> _confirmDelete(BuildContext context, SheetMusic sheet) async {
    return await showCupertinoModalPopup<bool>(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: const Text('Delete Sheet Music?'),
            message: Text('"${sheet.title}" will be permanently deleted.'),
            actions: [
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
        ) ??
        false;
  }
}

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentUserEmailProvider) ?? '-';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: MediaQuery.of(context).padding.copyWith(
              top: MediaQuery.of(context).padding.top - 40,
            ),
          ),
          child: CupertinoSliverNavigationBar(
            largeTitle: const Text('Settings'),
            backgroundColor: _navBarColor(context),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                _AccountCard(email: email, initial: initial),
                const SizedBox(height: 20),
                _LogoutButton(onLogout: onLogout),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.email, required this.initial});
  final String email;
  final String initial;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(color: _kAccent, shape: BoxShape.circle),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Logged In', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel)),
                    const SizedBox(height: 2),
                    Text(email,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: CupertinoColors.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 16),
          onPressed: onLogout,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.square_arrow_left, color: CupertinoColors.destructiveRed, size: 18),
              SizedBox(width: 8),
              Text('Log Out', style: TextStyle(color: CupertinoColors.destructiveRed, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
        ),
      );
}

Color _navBarColor(BuildContext context) =>
    CupertinoColors.systemGroupedBackground.resolveFrom(context).withValues(alpha: 0.94);

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor = _kAccent,
    this.inactiveColor = const Color(0xFF8E8E93),
  });

  final IconData icon;
  final IconData filledIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? filledIcon : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: color)),
          ],
        ),
      ),
    );
  }
}
