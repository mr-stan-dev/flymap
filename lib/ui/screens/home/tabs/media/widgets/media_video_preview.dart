import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_strings_builder.dart';
import 'package:flymap/ui/screens/sky_camera/sky_camera_video_overlay_timeline.dart';
import 'package:sky_camera/sky_camera.dart';
import 'package:video_player/video_player.dart';

/// Full-screen playback of a sky-camera video: the CLEAN clip with the GPS
/// overlay drawn live on top from the recorded 1 Hz track — no burned file
/// needed to watch it in the app.
class MediaVideoPreview extends StatefulWidget {
  const MediaVideoPreview({
    required this.capture,
    this.bottomControlsInset = 0,
    super.key,
  }) : assert(bottomControlsInset >= 0);

  final SkyCameraMediaItem capture;

  /// Space reserved below the seek bar for preview controls owned by the
  /// parent, such as the capture filmstrip.
  final double bottomControlsInset;

  @override
  State<MediaVideoPreview> createState() => _MediaVideoPreviewState();
}

class _MediaVideoPreviewState extends State<MediaVideoPreview> {
  late final VideoPlayerController _controller;
  late final SkyCameraVideoOverlayTimeline _timeline;
  SkyCameraStrings? _strings;
  int _overlaySecond = -1;
  SkyCameraOverlaySnapshot? _overlaySnapshot;
  bool _initFailed = false;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _timeline = SkyCameraVideoOverlayTimeline(widget.capture);
    _controller = VideoPlayerController.file(File(widget.capture.sourcePath));
    _controller.addListener(_handlePlayerTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bootstraps here, NOT in initState: the strings builder reads the
    // localization inherited widget, which throws during initState.
    if (_bootstrapped) return;
    _bootstrapped = true;
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final strings = await FlymapSkyCameraStringsBuilder.build(context);
      if (!mounted) return;
      setState(() => _strings = strings);
      await _controller.initialize();
      await _controller.setLooping(true);
      if (!mounted) return;
      setState(() {});
      await _controller.play();
    } catch (error, stackTrace) {
      debugPrint('MediaVideoPreview init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _initFailed = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handlePlayerTick);
    _controller.dispose();
    super.dispose();
  }

  void _handlePlayerTick() {
    final positionMs = _controller.value.position.inMilliseconds;
    final second = positionMs ~/ 1000;
    if (second == _overlaySecond) return;
    _overlaySecond = second;
    setState(() {
      _overlaySnapshot = _timeline.snapshotAt(second * 1000);
    });
  }

  void _togglePlayback() {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      unawaited(_controller.pause());
    } else {
      unawaited(_controller.play());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      return Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: Colors.white.withValues(alpha: 0.72),
        ),
      );
    }
    final strings = _strings;
    if (!_controller.value.isInitialized || strings == null) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }

    final overlaySnapshot = _overlaySnapshot ?? _timeline.snapshotAt(0);
    return GestureDetector(
      key: const Key('media.video_preview'),
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoPlayer(_controller),
                  IgnorePointer(
                    child: SkyCameraOverlayView(
                      snapshot: overlaySnapshot,
                      strings: strings,
                      metricsPosition: SkyCameraMetricsPosition.initial,
                      onMetricsPositionChanged: (_) {},
                    ),
                  ),
                  if (!_controller.value.isPlaying)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: widget.bottomControlsInset,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 10),
              child: _MediaVideoScrubber(controller: _controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaVideoScrubber extends StatelessWidget {
  const _MediaVideoScrubber({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final durationMs = controller.value.duration.inMilliseconds;
        final max = durationMs > 0 ? durationMs.toDouble() : 1.0;
        final position = controller.value.position.inMilliseconds
            .clamp(0, durationMs > 0 ? durationMs : 0)
            .toDouble();

        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            key: const Key('media.video_scrubber'),
            value: position,
            max: max,
            onChanged: durationMs <= 0
                ? null
                : (value) => unawaited(
                    controller.seekTo(Duration(milliseconds: value.round())),
                  ),
          ),
        );
      },
    );
  }
}
