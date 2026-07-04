import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_zoom_selector.dart';

class SkyCameraBottomBar extends StatelessWidget {
  const SkyCameraBottomBar({
    required this.isCapturing,
    required this.thumbnailPath,
    required this.onCapture,
    required this.onThumbnailTap,
    required this.zoomLevels,
    required this.currentZoomLevel,
    required this.onZoomSelected,
    super.key,
  });

  final bool isCapturing;
  final String? thumbnailPath;
  final VoidCallback? onCapture;
  final VoidCallback? onThumbnailTap;
  final List<double> zoomLevels;
  final double currentZoomLevel;
  final ValueChanged<double> onZoomSelected;

  @override
  Widget build(BuildContext context) {
    final thumbnailPath = this.thumbnailPath;
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SkyCameraZoomSelector(
              zoomLevels: zoomLevels,
              currentZoomLevel: currentZoomLevel,
              onSelected: onZoomSelected,
            ),
          ),
          Positioned(
            top: 52,
            left: 0,
            right: 0,
            height: 84,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: thumbnailPath != null
                          ? _SkyCameraThumbnail(
                              path: thumbnailPath,
                              isSaving: isCapturing,
                              onTap: onThumbnailTap,
                            )
                          : isCapturing
                          ? const _SkyCameraSavingThumbnail()
                          : const SizedBox(width: 72, height: 72),
                    ),
                  ),
                  _SkyCameraCaptureButton(
                    isCapturing: isCapturing,
                    onCapture: onCapture,
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
          Positioned(
            top: 146,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'PHOTO',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyCameraCaptureButton extends StatelessWidget {
  const _SkyCameraCaptureButton({
    required this.isCapturing,
    required this.onCapture,
  });

  final bool isCapturing;
  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('sky_camera.capture_button'),
      onTap: onCapture,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: isCapturing ? 0.98 : 1,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
              width: 6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: isCapturing ? 14 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCapturing
                  ? const Color(0xFFF1F4F8)
                  : const Color(0xFFFFFFFF),
              border: Border.all(
                color: const Color(
                  0xFF0A0E16,
                ).withValues(alpha: isCapturing ? 0.14 : 0.08),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkyCameraThumbnail extends StatelessWidget {
  const _SkyCameraThumbnail({
    required this.path,
    required this.isSaving,
    required this.onTap,
  });

  final String path;
  final bool isSaving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('sky_camera.last_capture_thumbnail'),
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF111827)),
            Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFF1A2232)),
                child: Center(
                  child: Icon(
                    _iconForPath(path),
                    size: 22,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ),
            if (isSaving)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      key: Key('sky_camera.saving_thumbnail_indicator'),
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForPath(String path) {
    final dotIndex = path.lastIndexOf('.');
    final extension = dotIndex >= 0
        ? path.substring(dotIndex).toLowerCase()
        : '';
    if (extension == '.png' || extension == '.jpg' || extension == '.jpeg') {
      return Icons.photo_rounded;
    }
    return Icons.broken_image_outlined;
  }
}

class _SkyCameraSavingThumbnail extends StatelessWidget {
  const _SkyCameraSavingThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('sky_camera.last_capture_thumbnail'),
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xCC121824),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            key: Key('sky_camera.saving_thumbnail_indicator'),
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
