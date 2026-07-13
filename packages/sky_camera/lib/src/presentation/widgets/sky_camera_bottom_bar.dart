import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_zoom_selector.dart';

enum SkyCameraCaptureMode { photo, video }

class SkyCameraBottomBar extends StatelessWidget {
  const SkyCameraBottomBar({
    required this.isCapturing,
    required this.thumbnailPath,
    required this.onCapture,
    required this.onThumbnailTap,
    required this.zoomLevels,
    required this.currentZoomLevel,
    required this.onZoomSelected,
    this.captureMode = SkyCameraCaptureMode.photo,
    this.isRecording = false,
    this.isTransitioning = false,
    this.recordingElapsed,
    this.maxRecordingDuration,
    this.onCaptureModeChanged,
    super.key,
  });

  final bool isCapturing;
  final String? thumbnailPath;
  final VoidCallback? onCapture;
  final VoidCallback? onThumbnailTap;
  final List<double> zoomLevels;
  final double currentZoomLevel;
  final ValueChanged<double> onZoomSelected;
  final SkyCameraCaptureMode captureMode;
  final bool isRecording;
  final bool isTransitioning;

  /// Elapsed time of the active recording; drives the shutter countdown.
  final Duration? recordingElapsed;
  final Duration? maxRecordingDuration;
  final ValueChanged<SkyCameraCaptureMode>? onCaptureModeChanged;

  static const _thumbnailSize = 72 * 0.8;
  static const _thumbnailRadius = 18 * 0.8;
  static const _thumbnailProgressSize = 20 * 0.8;

  @override
  Widget build(BuildContext context) {
    final thumbnailPath = this.thumbnailPath;
    return SizedBox(
      key: const Key('sky_camera.bottom_bar'),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: thumbnailPath != null
                        ? _SkyCameraThumbnail(
                            path: thumbnailPath,
                            isSaving: isCapturing,
                            onTap: isRecording || isTransitioning
                                ? null
                                : onThumbnailTap,
                          )
                        : isCapturing
                        ? const _SkyCameraSavingThumbnail()
                        : const SizedBox.square(dimension: _thumbnailSize),
                  ),
                ),
                _SkyCameraCaptureButton(
                  isCapturing: isCapturing,
                  isVideoMode: captureMode == SkyCameraCaptureMode.video,
                  isRecording: isRecording,
                  recordingElapsed: recordingElapsed,
                  maxRecordingDuration: maxRecordingDuration,
                  onCapture: onCapture,
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          Positioned(
            top: 146,
            left: 0,
            right: 0,
            child: Center(
              child: _SkyCameraModeSelector(
                captureMode: captureMode,
                enabled: !isRecording && !isCapturing && !isTransitioning,
                onChanged: onCaptureModeChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyCameraModeSelector extends StatelessWidget {
  const _SkyCameraModeSelector({
    required this.captureMode,
    required this.enabled,
    required this.onChanged,
  });

  final SkyCameraCaptureMode captureMode;
  final bool enabled;
  final ValueChanged<SkyCameraCaptureMode>? onChanged;

  /// Swipe left advances to the next mode label, swipe right goes back —
  /// mirroring how the big camera apps move their mode strips.
  void _handleSwipe(DragEndDetails details) {
    if (!enabled || onChanged == null) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 100) return;
    final modes = SkyCameraCaptureMode.values;
    final index = modes.indexOf(captureMode);
    final nextIndex = velocity < 0 ? index + 1 : index - 1;
    if (nextIndex < 0 || nextIndex >= modes.length) return;
    onChanged!(modes[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('sky_camera.mode_selector'),
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: _handleSwipe,
      child: _buildLabels(),
    );
  }

  Widget _buildLabels() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final mode in SkyCameraCaptureMode.values) ...[
          GestureDetector(
            key: Key('sky_camera.mode_${mode.name}'),
            behavior: HitTestBehavior.opaque,
            onTap: enabled && onChanged != null && mode != captureMode
                ? () => onChanged!(mode)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                // Camera-style caps labels, deliberately not localized —
                // matches the previous hardcoded PHOTO strip.
                mode == SkyCameraCaptureMode.photo ? 'PHOTO' : 'VIDEO',
                style: TextStyle(
                  color: mode == captureMode
                      ? const Color(0xFFFFD60A)
                      : Colors.white.withValues(alpha: enabled ? 0.94 : 0.4),
                  fontSize: 13,
                  fontWeight: mode == captureMode
                      ? FontWeight.w600
                      : FontWeight.w400,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SkyCameraCaptureButton extends StatelessWidget {
  const _SkyCameraCaptureButton({
    required this.isCapturing,
    required this.isVideoMode,
    required this.isRecording,
    required this.onCapture,
    this.recordingElapsed,
    this.maxRecordingDuration,
  });

  final bool isCapturing;
  final bool isVideoMode;
  final bool isRecording;
  final VoidCallback? onCapture;
  final Duration? recordingElapsed;
  final Duration? maxRecordingDuration;

  @override
  Widget build(BuildContext context) {
    final innerColor = isVideoMode
        ? const Color(0xFFE53935)
        : isCapturing
        ? const Color(0xFFF1F4F8)
        : const Color(0xFFFFFFFF);

    final elapsed = recordingElapsed;
    final maxDuration = maxRecordingDuration;
    final showCountdown = isRecording && elapsed != null && maxDuration != null;
    final remainingSeconds = showCountdown
        ? (maxDuration.inSeconds - elapsed.inSeconds).clamp(
            0,
            maxDuration.inSeconds,
          )
        : 0;
    final remainingFraction = showCountdown && maxDuration.inSeconds > 0
        ? remainingSeconds / maxDuration.inSeconds
        : 0.0;

    return GestureDetector(
      key: const Key('sky_camera.capture_button'),
      onTap: onCapture,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: isCapturing ? 0.98 : 1,
        curve: Curves.easeOut,
        child: SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isVideoMode
                      ? Colors.white.withValues(alpha: 0.92)
                      : Colors.white,
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
                  // The red core shrinks into a rounded stop square while
                  // recording — the universal camera affordance. Kept a
                  // rounded rectangle in BOTH states (radius 34 on a 68px
                  // box is a circle) so the implicit tween never mixes
                  // shapes.
                  width: isRecording ? 34 : 68,
                  height: isRecording ? 34 : 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isRecording ? 8 : 34),
                    color: innerColor,
                    border: isRecording
                        ? null
                        : Border.all(
                            color: const Color(
                              0xFF0A0E16,
                            ).withValues(alpha: isCapturing ? 0.14 : 0.08),
                          ),
                  ),
                  child: showCountdown
                      ? Text(
                          '$remainingSeconds',
                          key: const Key(
                            'sky_camera.recording_countdown_seconds',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        )
                      : null,
                ),
              ),
              if (showCountdown)
                // The arc empties toward zero over the outer ring; the
                // one-second tween keeps the sweep continuous between the
                // screen's whole-second rebuilds.
                Positioned.fill(
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 1),
                      tween: Tween<double>(end: remainingFraction),
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFE53935),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
        width: SkyCameraBottomBar._thumbnailSize,
        height: SkyCameraBottomBar._thumbnailSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            SkyCameraBottomBar._thumbnailRadius,
          ),
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
                    width: SkyCameraBottomBar._thumbnailProgressSize,
                    height: SkyCameraBottomBar._thumbnailProgressSize,
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
      width: SkyCameraBottomBar._thumbnailSize,
      height: SkyCameraBottomBar._thumbnailSize,
      decoration: BoxDecoration(
        color: const Color(0xCC121824),
        borderRadius: BorderRadius.circular(
          SkyCameraBottomBar._thumbnailRadius,
        ),
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
          width: SkyCameraBottomBar._thumbnailProgressSize,
          height: SkyCameraBottomBar._thumbnailProgressSize,
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
