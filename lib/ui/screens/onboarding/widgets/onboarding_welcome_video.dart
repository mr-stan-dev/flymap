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
      // Asset missing or platform playback failure: keep the poster image.
      _logger.log('Welcome video unavailable, using poster: $error');
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
    final poster = Image.asset(widget.posterAssetPath, fit: BoxFit.cover);

    return AnimatedSwitcher(
      duration: DsMotion.normal,
      // Expand children so both poster and video fill the available space.
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      child: (_isReady && controller != null)
          ? _CoverVideo(key: const ValueKey('video'), controller: controller)
          : KeyedSubtree(key: const ValueKey('poster'), child: poster),
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
