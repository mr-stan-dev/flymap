import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/home/tabs/media/media_capture_preview_screen.dart';
import 'package:flymap/ui/screens/home/tabs/media/viewmodel/media_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/media/viewmodel/media_tab_state.dart';
import 'package:flymap/ui/screens/home/tabs/media/widgets/media_capture_grid.dart';
import 'package:flymap/ui/screens/home/tabs/media/widgets/media_shared.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_share_service.dart';
import 'package:flymap/ui/screens/sky_camera/sky_camera_video_share_preparer.dart';
import 'package:get_it/get_it.dart';

class MediaFolderScreen extends StatefulWidget {
  const MediaFolderScreen({required this.folder, super.key});

  final MediaCaptureFolder folder;

  @override
  State<MediaFolderScreen> createState() => _MediaFolderScreenState();
}

class _MediaFolderScreenState extends State<MediaFolderScreen> {
  late final List<SkyCameraMediaItem> _captures = List<SkyCameraMediaItem>.of(
    widget.folder.captures,
  );
  final Set<String> _selectedCaptureIds = <String>{};

  bool get _isSelecting => _selectedCaptureIds.isNotEmpty;

  static const _deleteMenuValue = 'delete';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: _isSelecting
            ? IconButton(
                tooltip: context.t.common.cancel,
                onPressed: _clearSelection,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        titleSpacing: 0,
        title: _isSelecting
            ? Text(
                context.t.media.selectedCount(
                  count: _selectedCaptureIds.length,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.folder.title),
                  if (widget.folder.subtitle != null &&
                      widget.folder.subtitle!.isNotEmpty)
                    Text(
                      widget.folder.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
        actions: [
          if (_isSelecting)
            IconButton(
              tooltip: context.t.media.deleteAction,
              onPressed: _deleteSelectedCaptures,
              icon: const Icon(Icons.delete_outline_rounded),
            )
          else ...[
            IconButton(
              key: const Key('media.folder_share'),
              tooltip: context.t.media.share,
              onPressed: _shareCurrentFolder,
              icon: const Icon(Icons.share_outlined),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                if (value == _deleteMenuValue) {
                  await _deleteCurrentFolder();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: _deleteMenuValue,
                  child: Text(context.t.media.deleteFolder),
                ),
              ],
            ),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: MediaCaptureGrid(
          captures: _captures,
          selectedCaptureIds: _selectedCaptureIds,
          selectionMode: _isSelecting,
          bottomPadding: 16,
          onCaptureTap: _handleCaptureTap,
          onCaptureLongPress: (capture) => _toggleCaptureSelection(capture.id),
        ),
      ),
    );
  }

  void _clearSelection() {
    setState(_selectedCaptureIds.clear);
  }

  void _handleCaptureTap(SkyCameraMediaItem capture) {
    if (_isSelecting) {
      _toggleCaptureSelection(capture.id);
      return;
    }
    final mediaTabCubit = context.read<MediaTabCubit>();
    Navigator.of(context)
        .push<Set<String>>(
          MaterialPageRoute<Set<String>>(
            builder: (_) => MediaCapturePreviewScreen(
              captures: _captures,
              initialCaptureId: capture.id,
              onDelete: (captureId) =>
                  mediaTabCubit.deleteCaptureIds([captureId]),
            ),
          ),
        )
        .then((deletedCaptureIds) {
          if (deletedCaptureIds == null ||
              deletedCaptureIds.isEmpty ||
              !mounted) {
            return;
          }
          setState(() {
            _captures.removeWhere(
              (capture) => deletedCaptureIds.contains(capture.id),
            );
            _selectedCaptureIds.removeAll(deletedCaptureIds);
          });
          if (_captures.isEmpty && mounted) {
            Navigator.of(context).pop();
          }
        });
  }

  void _toggleCaptureSelection(String captureId) {
    setState(() {
      if (_selectedCaptureIds.contains(captureId)) {
        _selectedCaptureIds.remove(captureId);
      } else {
        _selectedCaptureIds.add(captureId);
      }
    });
  }

  Future<void> _deleteCurrentFolder() async {
    final confirmed = await showMediaDeleteConfirmDialog(
      context,
      title: context.t.media.deleteFolder,
      message: context.t.media.deleteFolderConfirm(count: _captures.length),
    );
    if (!confirmed || !mounted) return;
    await context.read<MediaTabCubit>().deleteCaptureIds(
      _captures.map((capture) => capture.id),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _shareCurrentFolder() async {
    final prepared = await prepareSkyCameraMediaForSharing(
      context,
      captures: _captures,
    );
    if (prepared == null || !mounted) return;
    setState(() {
      _captures
        ..clear()
        ..addAll(prepared);
    });
    await GetIt.I<FlymapSkyCameraShareService>().shareMediaItems(
      captures: prepared,
      sharePositionOrigin: mediaShareRectForContext(context),
      source: 'media_folder',
    );
  }

  Future<void> _deleteSelectedCaptures() async {
    final selectedCount = _selectedCaptureIds.length;
    final confirmed = await showMediaDeleteConfirmDialog(
      context,
      title: selectedCount == 1
          ? context.t.media.deleteFile
          : context.t.media.deleteFiles(count: selectedCount),
      message: selectedCount == 1
          ? context.t.media.deleteFileConfirm
          : context.t.media.deleteFilesConfirm(count: selectedCount),
    );
    if (!confirmed || !mounted) return;
    final ids = _selectedCaptureIds.toList(growable: false);
    await context.read<MediaTabCubit>().deleteCaptureIds(ids);
    if (!mounted) return;
    setState(() {
      _captures.removeWhere(
        (capture) => _selectedCaptureIds.contains(capture.id),
      );
      _selectedCaptureIds.clear();
    });
    if (_captures.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }
}
