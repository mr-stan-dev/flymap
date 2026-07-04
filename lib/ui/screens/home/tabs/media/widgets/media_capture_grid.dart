import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/ui/screens/home/tabs/media/widgets/media_shared.dart';

class MediaCaptureGrid extends StatelessWidget {
  const MediaCaptureGrid({
    required this.captures,
    required this.selectedCaptureIds,
    required this.selectionMode,
    required this.bottomPadding,
    required this.onCaptureTap,
    required this.onCaptureLongPress,
    super.key,
  });

  final List<SkyCameraMediaItem> captures;
  final Set<String> selectedCaptureIds;
  final bool selectionMode;
  final double bottomPadding;
  final ValueChanged<SkyCameraMediaItem> onCaptureTap;
  final ValueChanged<SkyCameraMediaItem> onCaptureLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 16.0;
        const spacing = 8.0;
        const minTileWidth = 108.0;
        final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
        final crossAxisCount =
            ((availableWidth + spacing) / (minTileWidth + spacing))
                .floor()
                .clamp(2, 4);
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            bottomPadding,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1,
          ),
          itemCount: captures.length,
          itemBuilder: (context, index) {
            final capture = captures[index];
            return MediaCaptureTile(
              capture: capture,
              isSelected: selectedCaptureIds.contains(capture.id),
              selectionMode: selectionMode,
              onTap: () => onCaptureTap(capture),
              onLongPress: () => onCaptureLongPress(capture),
            );
          },
        );
      },
    );
  }
}

class MediaCaptureTile extends StatelessWidget {
  const MediaCaptureTile({
    required this.capture,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final SkyCameraMediaItem capture;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('media.grid_thumbnail_${capture.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: MediaCaptureThumbnailImage(path: capture.galleryImagePath),
            ),
            if (selectionMode || isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: MediaSelectionBadge(selected: isSelected),
              ),
          ],
        ),
      ),
    );
  }
}
