import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:video_player/video_player.dart';

/// Full-bleed demo-flight video for the welcome step, cover-cropped to fill
/// whatever constraints it is given.
///
/// Plays [videoAssetPath] muted and looping (the asset is a reel of several
/// routes with crossfades, so the loop reads as continuous).
/// [posterAssetPath] shows until the first frame is ready and stays forever
/// if the video asset is missing or fails to play — the widget is purely
/// additive and can ship before the asset does.
class OnboardingWelcomeVideo extends StatefulWidget {
  const OnboardingWelcomeVideo({
    required this.videoAssetPath,
    required this.posterAssetPath,
    super.key,
  });

  final String videoAssetPath;
  final String posterAssetPath;

  @override
  State<OnboardingWelcomeVideo> createState() => _OnboardingWelcomeVideoState();
}

class _OnboardingWelcomeVideoState extends State<OnboardingWelcomeVideo> {
  static const _logger = Logger('OnboardingWelcomeVideo');

  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.asset(widget.videoAssetPath);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (error) {
      // Asset missing or platform playback failure: fall back to the poster.
      _logger.log('Welcome video unavailable, using poster: $error');
      if (!mounted) return;
      setState(() => _isFailed = true);
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    // Loading: a quiet placeholder in the scaffold color (the gradients
    // above/below fade into the same color, so the area reads as intentional
    // negative space) — flashing the old static poster before the video
    // looked like a broken frame. The poster remains only as the permanent
    // fallback when playback is impossible.
    final Widget child;
    if (_isReady && controller != null) {
      child = _CoverVideo(key: const ValueKey('video'), controller: controller);
    } else if (_isFailed) {
      child = KeyedSubtree(
        key: const ValueKey('poster'),
        child: Image.asset(widget.posterAssetPath, fit: BoxFit.cover),
      );
    } else {
      child = Container(
        key: const ValueKey('loading'),
        color: Theme.of(context).scaffoldBackgroundColor,
        alignment: Alignment.center,
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: DsMotion.normal,
      // Expand children so every state fills the available space.
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      child: child,
    );
  }
}

/// Fills the available space with the video, cropping like [BoxFit.cover].
class _CoverVideo extends StatelessWidget {
  const _CoverVideo({required this.controller, super.key});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width > 0 ? size.width : 1,
        height: size.height > 0 ? size.height : 1,
        child: VideoPlayer(controller),
      ),
    );
  }
}
