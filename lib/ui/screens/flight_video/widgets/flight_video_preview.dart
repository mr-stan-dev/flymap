import 'package:flutter/material.dart';
import 'package:flymap/domain/usecase/generate_flight_video_use_case.dart';

/// Looping live preview of the flight video.
///
/// Drives the same [FlightVideoSession] renderer the export uses, scaled
/// down to the widget size, so what the user watches is exactly what the
/// MP4 will contain.
class FlightVideoPreview extends StatefulWidget {
  const FlightVideoPreview({
    required this.session,
    this.playing = true,
    super.key,
  });

  final FlightVideoSession session;

  /// Pause while exporting: the export loop owns the decoded-tile cache and
  /// the UI thread, so a running preview would thrash both.
  final bool playing;

  @override
  State<FlightVideoPreview> createState() => _FlightVideoPreviewState();
}

class _FlightVideoPreviewState extends State<FlightVideoPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _decoding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.session.spec.duration,
    );
    _controller.addListener(_decodeAhead);
    if (widget.playing) _controller.repeat();
    _decodeAhead();
  }

  @override
  void didUpdateWidget(covariant FlightVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !oldWidget.playing) {
      _controller.repeat();
    } else if (!widget.playing && oldWidget.playing) {
      _controller.stop();
    }
  }

  /// Keeps the decoded-tile LRU warm for the current playhead plus ~1 s of
  /// look-ahead, so zoom/pitch transitions have their tiles ready. Missing
  /// tiles fall back to parents at paint time, so lag never shows holes.
  void _decodeAhead() {
    if (_decoding || !widget.playing) return;
    _decoding = true;
    final session = widget.session;
    final t = _controller.value;
    final lookAheadT = (t + 0.06) % 1.0;
    final tiles = {
      ...session.renderer.tilesForFrame(t),
      ...session.renderer.tilesForFrame(lookAheadT),
    };
    session.tileStore
        .ensureDecoded(tiles)
        .whenComplete(() => _decoding = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.session.spec;
    return AspectRatio(
      aspectRatio: spec.width / spec.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _FlightVideoPainter(
            session: widget.session,
            animation: _controller,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _FlightVideoPainter extends CustomPainter {
  _FlightVideoPainter({required this.session, required this.animation})
    : super(repaint: animation);

  final FlightVideoSession session;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final spec = session.spec;
    final scale = size.width / spec.width;
    canvas.save();
    canvas.scale(scale);
    session.renderer.paintFrame(canvas, animation.value);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlightVideoPainter oldDelegate) =>
      oldDelegate.session != session;
}
