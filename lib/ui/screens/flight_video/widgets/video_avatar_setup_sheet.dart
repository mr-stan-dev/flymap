import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/video_avatar_repository.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lightweight "pick your avatar" flow: choose a local photo (no upload, no
/// account) and crop the part you want — e.g. your face — with a simple square
/// cropper. The result is stored in [VideoAvatarRepository] for this and future
/// videos.
///
/// Returns true when the user saved an avatar, false if they dismissed it.
Future<bool> showVideoAvatarSetupSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _VideoAvatarSetupSheet(),
  );
  return result ?? false;
}

class _VideoAvatarSetupSheet extends StatefulWidget {
  const _VideoAvatarSetupSheet();

  @override
  State<_VideoAvatarSetupSheet> createState() => _VideoAvatarSetupSheetState();
}

class _VideoAvatarSetupSheetState extends State<_VideoAvatarSetupSheet> {
  final VideoAvatarRepository _repository = GetIt.I.get<VideoAvatarRepository>();
  final Logger _logger = const Logger('VideoAvatarSetup');

  String? _imagePath;
  bool _picking = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final config = await _repository.load();
    if (!mounted || !config.hasImage) return;
    setState(() => _imagePath = config.imagePath);
  }

  Future<void> _pickAndCrop() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      // In-app square cropper (pure Flutter, no native crop screen) so the user
      // can cut out just the face.
      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _AvatarCropPage(imageBytes: bytes),
        ),
      );
      if (cropped == null) return; // cancelled at the crop step

      final docs = await getApplicationDocumentsDirectory();
      // Unique filename per pick so a reused path never serves a stale, cached
      // bitmap in the preview.
      final dest = p.join(
        docs.path,
        'video_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(dest).writeAsBytes(cropped);
      if (!mounted) return;
      setState(() => _imagePath = dest);
    } catch (e) {
      _logger.error('Avatar pick/crop failed: $e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final path = _imagePath;
    if (path == null || _saving) return;
    setState(() => _saving = true);
    final prior = await _repository.load();
    await _repository.setImagePath(path);
    // Best-effort cleanup of a superseded avatar file.
    final old = prior.imagePath;
    if (old != null && old != path) {
      try {
        await File(old).delete();
      } catch (_) {
        // Orphaned file is harmless; ignore.
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final hasImage = _imagePath != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DsSpacing.lg,
          0,
          DsSpacing.lg,
          DsSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.flightVideo.avatarSetupTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            Center(
              child: _AvatarPreview(
                imagePath: _imagePath,
                busy: _picking,
                onTap: _pickAndCrop,
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            Center(
              child: TextButton.icon(
                onPressed: _picking ? null : _pickAndCrop,
                icon: Icon(
                  hasImage
                      ? Icons.photo_camera_back_outlined
                      : Icons.add_a_photo_outlined,
                  size: 18,
                ),
                label: Text(
                  hasImage
                      ? t.flightVideo.avatarChange
                      : t.flightVideo.avatarPick,
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            PrimaryButton(
              label: t.flightVideo.avatarSave,
              onPressed: hasImage && !_saving ? _save : null,
              isLoading: _saving,
              leadingIcon: Icons.check_rounded,
            ),
            const SizedBox(height: DsSpacing.xs),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(t.common.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.imagePath,
    required this.busy,
    required this.onTap,
  });

  final String? imagePath;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 120.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.colorScheme.primary, width: 2.5),
          image: imagePath != null
              ? DecorationImage(
                  image: FileImage(File(imagePath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: busy
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              )
            : imagePath == null
            ? Icon(
                Icons.add_a_photo_outlined,
                size: 34,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
    );
  }
}

/// Full-screen square/circle cropper (pure Flutter — no native crop screen).
/// Returns the cropped image bytes, or null if dismissed.
class _AvatarCropPage extends StatefulWidget {
  const _AvatarCropPage({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<_AvatarCropPage> {
  final CropController _controller = CropController();
  bool _cropping = false;

  void _confirm() {
    if (_cropping) return;
    setState(() => _cropping = true);
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(t.flightVideo.avatarSetupTitle),
        actions: [
          IconButton(
            tooltip: t.common.ok,
            icon: _cropping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            onPressed: _cropping ? null : _confirm,
          ),
        ],
      ),
      body: Crop(
        image: widget.imageBytes,
        controller: _controller,
        // Circular guide (fixes aspect to 1); a fixed rect the user pans/zooms
        // the photo behind, framing their face.
        withCircleUi: true,
        interactive: true,
        fixCropRect: true,
        baseColor: Colors.black,
        maskColor: Colors.black.withValues(alpha: 0.55),
        onCropped: (result) {
          if (!mounted) return;
          if (result is CropSuccess) {
            Navigator.of(context).pop(result.croppedImage);
          } else {
            setState(() => _cropping = false);
          }
        },
      ),
    );
  }
}
