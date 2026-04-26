import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/sheet_music.dart';

class SheetMusicCard extends StatelessWidget {
  final SheetMusic sheet;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SheetMusicCard({
    super.key,
    required this.sheet,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(sheet.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: CupertinoColors.destructiveRed,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(0),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: onTap,
        child: ColoredBox(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _Thumbnail(imagePath: sheet.imagePath),
                const SizedBox(width: 14),
                Expanded(child: _CardInfo(sheet: sheet)),
                const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey3, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final thumb = imagePath.split(',').where((p) => p.trim().isNotEmpty).firstOrNull ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 68,
        child: thumb.isEmpty
            ? const ColoredBox(
                color: CupertinoColors.systemGrey5,
                child: Center(child: Icon(CupertinoIcons.music_note, color: CupertinoColors.systemGrey2, size: 22)),
              )
            : Image.file(
                File(thumb),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: CupertinoColors.systemGrey5,
                  child: Center(child: Icon(CupertinoIcons.music_note, color: CupertinoColors.systemGrey2, size: 22)),
                ),
              ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.sheet});
  final SheetMusic sheet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sheet.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          sheet.composer,
          style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
