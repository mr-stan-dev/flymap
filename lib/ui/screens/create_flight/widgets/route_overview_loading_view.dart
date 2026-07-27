import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Tangent;

import 'package:flutter/material.dart';

/// Universal loading view for the route-overview build: the airport pair
/// with a plane flying along a dashed arc between them, one status line, and
/// a reassurance hint that only appears when loading outlasts [hintDelay].
///
/// Works for any duration — a fast approximate-route build shows a brief
/// flight animation, a slow FR24 build gains the hint — with no staged
/// progress that could misrepresent the single backend call behind it.
class RouteOverviewLoadingView extends StatefulWidget {
  const RouteOverviewLoadingView({
    required this.departureCode,
    required this.arrivalCode,
    required this.statusText,
    this.hintText,
    this.hintDelay = const Duration(milliseconds: 2500),
    super.key,
  });

  final String departureCode;
  final String arrivalCode;
  final String statusText;
  final String? hintText;
  final Duration hintDelay;

  @override
  State<RouteOverviewLoadingView> createState() =>
      _RouteOverviewLoadingViewState();
}

class _RouteOverviewLoadingViewState extends State<RouteOverviewLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  Timer? _hintTimer;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    if (widget.hintText != null) {
      _hintTimer = Timer(widget.hintDelay, () {
        if (mounted) setState(() => _showHint = true);
      });
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final codeStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.departureCode, style: codeStyle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 140,
                height: 56,
                child: AnimatedBuilder(
                  animation: _flight,
                  builder: (context, _) => CustomPaint(
                    painter: _FlyingRoutePainter(
                      color: colorScheme.primary,
                      progress: Curves.easeInOutSine.transform(_flight.value),
                    ),
                  ),
                ),
              ),
            ),
            Text(widget.arrivalCode, style: codeStyle),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.statusText,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        if (widget.hintText != null) ...[
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _showHint ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: Text(
              widget.hintText!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Dashed arc between the airport pair with a plane travelling along it;
/// the trail behind the plane is drawn solid so motion reads as progress
/// even though the underlying build gives no incremental signal.
class _FlyingRoutePainter extends CustomPainter {
  const _FlyingRoutePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  static const double _dashLength = 5.0;
  static const double _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(2, size.height * 0.82);
    final end = Offset(size.width - 2, size.height * 0.82);
    final control = Offset(size.width / 2, -size.height * 0.25);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final metric = path.computeMetrics().first;
    final planeOffset = metric.length * progress;

    final dashedPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    var distance = 0.0;
    while (distance < metric.length) {
      final dashEnd = math.min(distance + _dashLength, metric.length);
      canvas.drawPath(metric.extractPath(distance, dashEnd), dashedPaint);
      distance += _dashLength + _dashGap;
    }

    final trailPaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (planeOffset > 0) {
      canvas.drawPath(metric.extractPath(0, planeOffset), trailPaint);
    }

    final tangent = metric.getTangentForOffset(planeOffset);
    if (tangent != null) {
      _drawPlane(canvas, tangent);
    }

    canvas.drawCircle(start, 2.6, Paint()..color = color);
    canvas.drawCircle(end, 2.6, Paint()..color = color);
  }

  void _drawPlane(Canvas canvas, Tangent tangent) {
    const planeSize = 18.0;
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.flight.codePoint),
        style: TextStyle(
          fontSize: planeSize,
          fontFamily: Icons.flight.fontFamily,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    // Icons.flight points up; rotate onto the direction of travel.
    canvas.rotate(tangent.angle * -1 + math.pi / 2);
    textPainter.paint(canvas, const Offset(-planeSize / 2, -planeSize / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlyingRoutePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
