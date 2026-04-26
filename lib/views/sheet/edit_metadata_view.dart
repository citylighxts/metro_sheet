import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sheet_music.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/device_service.dart';

class EditMetadataScreen extends ConsumerStatefulWidget {
  const EditMetadataScreen({super.key, this.imagePath, this.existingSheet})
    : assert(
        imagePath != null || existingSheet != null,
        'Provide either imagePath or existingSheet',
      );

  final String? imagePath;
  final SheetMusic? existingSheet;

  @override
  ConsumerState<EditMetadataScreen> createState() => _EditMetadataScreenState();
}

class _EditMetadataScreenState extends ConsumerState<EditMetadataScreen> {
  final _titleController = TextEditingController();
  final _composerController = TextEditingController();
  final _bpmController = TextEditingController(text: '120');
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  late String _initialTitle;
  late String _initialComposer;
  late String _initialBpm;

  bool get _isEditing => widget.existingSheet != null;

  bool get _hasUnsavedChanges {
    if (_isSaving) return false;
    return _titleController.text.trim() != _initialTitle ||
        _composerController.text.trim() != _initialComposer ||
        _bpmController.text.trim() != _initialBpm;
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingSheet != null) {
      _titleController.text = widget.existingSheet!.title;
      _composerController.text = widget.existingSheet!.composer;
      _bpmController.text = widget.existingSheet!.bpm.toString();
    }
    _initialTitle = _titleController.text.trim();
    _initialComposer = _composerController.text.trim();
    _initialBpm = _bpmController.text.trim();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _bpmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final sheet = _buildSheetMusic();
      final success = _isEditing
          ? await ref.read(homeViewModelProvider.notifier).updateSheetMusic(sheet)
          : (await ref.read(homeViewModelProvider.notifier).addSheetMusic(sheet)) != null;

      if (!mounted) return;
      if (success) {
        await ref.read(deviceServiceProvider).showSaveSuccessNotification(
          _titleController.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        await _showErrorDialog('Failed to save data to SQLite.');
      }
    } catch (e) {
      if (mounted) await _showErrorDialog('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  SheetMusic _buildSheetMusic() => SheetMusic(
    id: _isEditing ? widget.existingSheet!.id : null,
    title: _titleController.text.trim(),
    composer: _composerController.text.trim(),
    bpm: int.parse(_bpmController.text.trim()),
    imagePath: _isEditing ? widget.existingSheet!.imagePath : widget.imagePath!,
    createdAt: _isEditing ? widget.existingSheet!.createdAt : DateTime.now(),
  );

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Oops'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    return await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Unsaved Changes'),
        message: const Text('Are you sure you want to leave? Your changes will be lost.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard Changes'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Continue Editing'),
        ),
      ),
    ) ?? false;
  }

  Future<void> _handleCancel() async {
    final canExit = await _confirmDiscardChanges();
    if (!mounted || !canExit) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final rawPathStr = widget.existingSheet?.imagePath ?? widget.imagePath!;
    final thumbnailPath = rawPathStr.split(',').where((p) => p.trim().isNotEmpty).firstOrNull ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canExit = await _confirmDiscardChanges();
        if (mounted && canExit) Navigator.of(context).pop(false);
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _isSaving ? null : _handleCancel,
            child: const Text('Cancel'),
          ),
          middle: Text(_isEditing ? 'Edit Sheet Music' : 'New Sheet Music'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const CupertinoActivityIndicator()
                : Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _ImagePreview(thumbnailPath: thumbnailPath),
                _MetadataFormSection(
                  formKey: _formKey,
                  titleController: _titleController,
                  composerController: _composerController,
                  bpmController: _bpmController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.thumbnailPath});
  final String thumbnailPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(thumbnailPath),
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          cacheWidth: 800,
          errorBuilder: (_, __, ___) => DecoratedBox(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SizedBox(
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.photo, size: 40, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                  const SizedBox(height: 8),
                  const Text('Preview tidak tersedia', style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataFormSection extends StatelessWidget {
  const _MetadataFormSection({
    required this.formKey,
    required this.titleController,
    required this.composerController,
    required this.bpmController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController composerController;
  final TextEditingController bpmController;

  static const _rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  static const _textStyle = TextStyle(fontSize: 16, color: CupertinoColors.label);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: CupertinoFormSection.insetGrouped(
      backgroundColor: const Color(0x00000000),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        RepaintBoundary(
          child: CupertinoTextFormFieldRow(
            controller: titleController,
            textInputAction: TextInputAction.next,
            padding: _rowPadding,
            placeholder: 'Judul',
            style: _textStyle,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
          ),
        ),
        RepaintBoundary(
          child: CupertinoTextFormFieldRow(
            controller: composerController,
            textInputAction: TextInputAction.next,
            padding: _rowPadding,
            placeholder: 'Komposer',
            style: _textStyle,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Komposer wajib diisi' : null,
          ),
        ),
        RepaintBoundary(
          child: CupertinoTextFormFieldRow(
            controller: bpmController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            padding: _rowPadding,
            placeholder: 'BPM (20 – 300)',
            style: _textStyle,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'BPM wajib diisi';
              final bpm = int.tryParse(v.trim());
              if (bpm == null || bpm < 20 || bpm > 300) return 'BPM harus antara 20 – 300';
              return null;
            },
          ),
        ),
      ],
      ),
    );
  }
}
