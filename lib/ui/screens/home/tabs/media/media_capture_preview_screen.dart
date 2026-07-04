import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/home/tabs/media/widgets/media_shared.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_share_service.dart';
import 'package:get_it/get_it.dart';

class MediaCapturePreviewScreen extends StatefulWidget {
  const MediaCapturePreviewScreen({
    required this.captures,
    required this.initialCaptureId,
    required this.onDelete,
    super.key,
  }) : assert(captures.length > 0);

  final List<SkyCameraMediaItem> captures;
  final String initialCaptureId;
  final Future<void> Function(String captureId) onDelete;

  @override
  State<MediaCapturePreviewScreen> createState() =>
      _MediaCapturePreviewScreenState();
}

class _MediaCapturePreviewScreenState extends State<MediaCapturePreviewScreen> {
  static const _shareMenuValue = 'share';
  static const _deleteMenuValue = 'delete';
  static const _thumbnailExtent = 64.0;
  static const _thumbnailGap = 8.0;

  late final List<SkyCameraMediaItem> _captures;
  late final PageController _pageController;
  final ScrollController _thumbnailController = ScrollController();
  final Set<String> _deletedCaptureIds = {};
  late int _currentIndex;
  bool _allowPop = false;

  SkyCameraMediaItem get _currentCapture => _captures[_currentIndex];

  @override
  void initState() {
    super.initState();
    _captures = List<SkyCameraMediaItem>.of(widget.captures);
    final requestedIndex = _captures.indexWhere(
      (capture) => capture.id == widget.initialCaptureId,
    );
    _currentIndex = requestedIndex >= 0 ? requestedIndex : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capture = _currentCapture;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: _close,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(capture.routeLabel ?? context.t.media.previewTitle),
          actions: [
            PopupMenuButton<String>(
              key: const Key('media.capture_preview_menu'),
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: _shareMenuValue,
                  child: Text(context.t.media.share),
                ),
                PopupMenuItem<String>(
                  value: _deleteMenuValue,
                  child: Text(context.t.media.deleteFile),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: const Key('media.capture_preview_page_view'),
              controller: _pageController,
              itemCount: _captures.length,
              onPageChanged: _handlePageChanged,
              itemBuilder: (context, index) {
                return Center(
                  child: Image.file(
                    File(_captures[index].galleryImagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                );
              },
            ),
            if (_captures.length > 1)
              Align(
                alignment: Alignment.bottomCenter,
                child: _MediaPreviewFilmstrip(
                  captures: _captures,
                  currentIndex: _currentIndex,
                  controller: _thumbnailController,
                  thumbnailExtent: _thumbnailExtent,
                  gap: _thumbnailGap,
                  onCaptureTap: _showCapture,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String value) async {
    if (value == _shareMenuValue) {
      await GetIt.I<FlymapSkyCameraShareService>().shareMediaItems(
        captures: [_currentCapture],
        sharePositionOrigin: mediaShareRectForContext(context),
      );
      return;
    }
    if (value != _deleteMenuValue) return;
    await _deleteCurrentCapture();
  }

  Future<void> _deleteCurrentCapture() async {
    final capture = _currentCapture;
    final confirmed = await showMediaDeleteConfirmDialog(
      context,
      title: context.t.media.deleteFile,
      message: context.t.media.deleteFileConfirm,
    );
    if (!confirmed || !mounted) return;
    await widget.onDelete(capture.id);
    if (!mounted) return;

    _deletedCaptureIds.add(capture.id);
    if (_captures.length == 1) {
      _close();
      return;
    }
    _captures.removeAt(_currentIndex);
    _currentIndex = _currentIndex.clamp(0, _captures.length - 1);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(_currentIndex);
      _scrollToCurrentThumbnail();
    });
  }

  void _handlePageChanged(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _scrollToCurrentThumbnail();
  }

  void _showCapture(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToCurrentThumbnail() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_thumbnailController.hasClients) return;
      final viewportWidth = _thumbnailController.position.viewportDimension;
      final itemWidth = _thumbnailExtent + _thumbnailGap;
      final target =
          (_currentIndex * itemWidth) -
          ((viewportWidth - _thumbnailExtent) / 2);
      _thumbnailController.animateTo(
        target.clamp(0.0, _thumbnailController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _close() {
    if (_allowPop) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop<Set<String>>(Set<String>.unmodifiable(_deletedCaptureIds));
    });
  }
}

class _MediaPreviewFilmstrip extends StatelessWidget {
  const _MediaPreviewFilmstrip({
    required this.captures,
    required this.currentIndex,
    required this.controller,
    required this.thumbnailExtent,
    required this.gap,
    required this.onCaptureTap,
  });

  final List<SkyCameraMediaItem> captures;
  final int currentIndex;
  final ScrollController controller;
  final double thumbnailExtent;
  final double gap;
  final ValueChanged<int> onCaptureTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return SafeArea(
      top: false,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: 0.78),
            ],
          ),
        ),
        child: ListView.separated(
          key: const Key('media.capture_preview_filmstrip'),
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: captures.length,
          separatorBuilder: (_, _) => SizedBox(width: gap),
          itemBuilder: (context, index) {
            final capture = captures[index];
            final selected = index == currentIndex;
            return GestureDetector(
              key: Key('media.capture_preview_thumbnail_${capture.id}'),
              onTap: () => onCaptureTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: thumbnailExtent,
                height: thumbnailExtent,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? primaryColor : Colors.white30,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: MediaCaptureThumbnailImage(
                    path: capture.galleryImagePath,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
