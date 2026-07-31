import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:flymap/ui/screens/share_flight/widgets/map/share_image_painter.dart';

/// Draws the weather map overlay — dashed share-card route with the gap
/// traveling with the plane, airport markers, and the continuous cloud
/// field — over any canvas sized to the square weather viewport. Used by
/// the on-screen card AND the offscreen share/video renderer.
class WeatherMapPainter extends CustomPainter {
  WeatherMapPainter({
    required this.projectedRoute,
    required this.cloudFrames,
    required this.routeKm,
    required this.departureCode,
    required this.arrivalCode,
    required this.showClouds,
    required this.planeProgress,
    this.cloudOpacity = 1.0,
  });

  /// Offsets in the square viewport space; scaled to canvas size in paint.
  final List<Offset> projectedRoute;

  /// bilinear filtering; empty until built (or for free users).
  final List<ui.Image> cloudFrames;
  final double routeKm;
  final String departureCode;
  final String arrivalCode;
  final bool showClouds;
  final double? planeProgress;

  /// 0..1 fade for the cloud layer — frames arrive a beat after the map
  /// (background rasterization), so the card fades them in instead of
  /// popping. Route/plane/labels are never faded.
  final double cloudOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (projectedRoute.length < 2) return;
    final scale = size.width / staticWeatherMapSize;
    final routePoints = projectedRoute
        .map((p) => p * scale)
        .toList(growable: false);

    if (showClouds && cloudOpacity > 0) _drawClouds(canvas, size);

    final path = ShareImagePainter.buildRoutePath(
      routePoints,
      routeKm: routeKm,
    );
    // Same visual language as the home-card thumbnails: the share card's
    // dashed teal route, scaled to this card's stroke width.
    final routePaint = Paint()
      ..color = ShareImagePainter.routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;
    final dashK = routePaint.strokeWidth / ShareImagePainter.routeStrokeWidth;
    final dashLength = ShareImagePainter.routeDashLength * dashK;
    final dashGap = ShareImagePainter.routeDashGap * dashK;

    final progress = planeProgress;
    final metrics = path.computeMetrics().toList(growable: false);
    if (progress != null && metrics.isNotEmpty) {
      // The dash pattern is anchored at the path START and never moves —
      // only the plane's gap window travels; dashes inside it are skipped
      // (clipped at its edges), like a plane flying over a printed line.
      final metric = metrics.first;
      final planeOffset = metric.length * progress;
      final halfGap = ShareImagePainter.planeGapLength * dashK / 2;
      _drawDashedPath(
        canvas,
        path,
        routePaint,
        dashLength: dashLength,
        dashGap: dashGap,
        skipStart: math.max(0.0, planeOffset - halfGap),
        skipEnd: math.min(metric.length, planeOffset + halfGap),
      );
    } else {
      _drawDashedPath(
        canvas,
        path,
        routePaint,
        dashLength: dashLength,
        dashGap: dashGap,
      );
    }

    _drawAirport(canvas, routePoints.first, departureCode, scale, size);
    _drawAirport(canvas, routePoints.last, arrivalCode, scale, size);

    if (progress != null) _drawPlane(canvas, path, progress, scale);
  }

  /// Draws the dash pattern with a fixed phase (anchored at the path
  /// start). Dashes overlapping [skipStart]..[skipEnd] — the plane's gap —
  /// are clipped/skipped, so the pattern itself never moves.
  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double dashLength,
    required double dashGap,
    double skipStart = 0,
    double skipEnd = 0,
  }) {
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : dashGap;
        if (draw) {
          final dashStart = distance;
          final dashEnd = math.min(distance + length, metric.length);
          if (dashEnd <= skipStart || dashStart >= skipEnd) {
            canvas.drawPath(metric.extractPath(dashStart, dashEnd), paint);
          } else {
            // Dash overlaps the plane gap: draw only the outside parts.
            if (dashStart < skipStart) {
              canvas.drawPath(metric.extractPath(dashStart, skipStart), paint);
            }
            if (dashEnd > skipEnd) {
              canvas.drawPath(metric.extractPath(skipEnd, dashEnd), paint);
            }
          }
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  /// The continuous cloud layer: the current flight instant selects two
  /// adjacent field frames, blended exactly (plus-add inside an isolated
  /// layer) so the field morphs smoothly as the plane progresses — clouds
  /// thicken, thin out, and drift instead of stepping.
  void _drawClouds(Canvas canvas, Size size) {
    if (cloudFrames.isEmpty) return;
    final rect = Offset.zero & size;
    final first = cloudFrames.first;
    final src = Rect.fromLTWH(
      0,
      0,
      first.width.toDouble(),
      first.height.toDouble(),
    );
    final progress = planeProgress;
    if (cloudFrames.length == 1 || progress == null) {
      canvas.drawImageRect(
        first,
        src,
        rect,
        Paint()
          ..filterQuality = FilterQuality.high
          ..color = Colors.white.withValues(alpha: cloudOpacity),
      );
      return;
    }

    final framePosition = progress * (cloudFrames.length - 1);
    final index = framePosition.floor().clamp(0, cloudFrames.length - 2);
    final blend = framePosition - index;
    canvas.saveLayer(rect, Paint());
    // Continuous sub-frame drift in the same direction as the baked noise
    // motion — the field visibly moves at frame rate, not only when the
    // crossfade advances. Drawn slightly inflated so edges never gap.
    canvas.translate((0.5 - progress) * 20, (0.5 - progress) * 7);
    final dst = rect.inflate(14);
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withValues(alpha: (1 - blend) * cloudOpacity);
    canvas.drawImageRect(cloudFrames[index], src, dst, paint);
    paint
      ..color = Colors.white.withValues(alpha: blend * cloudOpacity)
      ..blendMode = BlendMode.plus;
    canvas.drawImageRect(cloudFrames[index + 1], src, dst, paint);
    canvas.restore();
  }

  void _drawAirport(
    Canvas canvas,
    Offset center,
    String code,
    double scale,
    Size size,
  ) {
    // Share-card endpoint style: white ring with a teal core.
    canvas.drawCircle(center, 10.5 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      8.25 * scale,
      Paint()..color = ShareImagePainter.routeColor,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: code,
        style: TextStyle(
          color: Colors.white,
          fontSize: 19.5 * scale,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var labelOrigin = center + Offset(-painter.width / 2, 14 * scale);
    // Keep labels inside the card.
    labelOrigin = Offset(
      labelOrigin.dx.clamp(4, size.width - painter.width - 4),
      labelOrigin.dy.clamp(4, size.height - painter.height - 4),
    );
    painter.paint(canvas, labelOrigin);
  }

  void _drawPlane(Canvas canvas, Path path, double progress, double scale) {
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent == null) return;

    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.flight.codePoint),
        style: TextStyle(
          fontSize: 39 * scale,
          fontFamily: Icons.flight.fontFamily,
          color: ShareImagePainter.routeColor,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    canvas.rotate(-tangent.angle + math.pi / 2);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(WeatherMapPainter oldDelegate) =>
      oldDelegate.planeProgress != planeProgress ||
      oldDelegate.showClouds != showClouds ||
      oldDelegate.cloudFrames != cloudFrames ||
      oldDelegate.cloudOpacity != cloudOpacity;
}
