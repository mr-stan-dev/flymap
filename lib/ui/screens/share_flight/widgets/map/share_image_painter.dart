import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight.dart';

/// Paints only map route primitives for the share card:
/// dashed polyline, plane marker, and endpoint pins.
class ShareImagePainter {
  ShareImagePainter({
    required this.flight,
    this.projectedPoints,
    this.planeImage,
  });

  final Flight flight;
  final List<Offset>? projectedPoints;
  final ui.Image? planeImage;

  /// Route styling shared with the home flight card's thumbnail overlay so
  /// both surfaces draw the route identically.
  static const Color routeColor = Color(0xFF47EFFF);
  static const double routeDashLength = 17.0;
  static const double routeDashGap = 13.0;
  static const double endpointOuterRadius = 12.0;
  static const double endpointInnerRadius = 10.0;
  static const String planeAssetPath = 'assets/images/icons/plane_teal.png';
  static const double planeGapLength = 80.0;
  static const double planeGapCenterForwardBias = 6.0;
  static const double routeStrokeWidth = 5.0;

  void paint(Canvas canvas, Size size) {
    _drawRoute(canvas, size);
  }

  void _drawRoute(Canvas canvas, Size size) {
    final points = projectedPoints;
    if (points == null || points.length < 2) return;
    if (points.any((p) => !p.dx.isFinite || !p.dy.isFinite)) return;

    final start = points.first;
    final end = points.last;
    final path = buildRoutePath(
      points,
      routeKm: flight.route.displayDistanceKm.toDouble(),
    );

    final routePaint = Paint()
      ..color = routeColor
      ..strokeWidth = routeStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final midOffset = metric.length * 0.5;
      // Plane icon is visually nose-heavy, so move the dashed-gap center
      // a bit forward to balance front/back visible spacing around the plane.
      final gapCenter = (midOffset + planeGapCenterForwardBias).clamp(
        0.0,
        metric.length,
      );
      final gapStart = max(0.0, gapCenter - (planeGapLength / 2));
      final gapEnd = min(metric.length, gapCenter + (planeGapLength / 2));

      if (gapStart > 0) {
        final segment = metric.extractPath(0, gapStart);
        _drawDashedPath(canvas, segment, routePaint);
      }
      if (gapEnd < metric.length) {
        final segment = metric.extractPath(gapEnd, metric.length);
        _drawDashedPath(canvas, segment, routePaint);
      }

      final tangent = metric.getTangentForOffset(midOffset);
      if (tangent != null) {
        _drawAirplane(canvas, tangent.position, tangent.vector);
      }
    } else {
      _drawDashedPath(canvas, path, routePaint);
    }

    _drawDot(canvas, start);
    _drawDot(canvas, end);
    _drawAirportCodeLabels(canvas, size, path, start, end);
  }

  /// Builds the drawn route: the real geometry, lightly simplified and
  /// corner-smoothed so GPS tracks read as one clean line. Endpoint-only
  /// routes (legacy flights without waypoints) fall back to the stylized arc.
  /// Shared with the home card thumbnail so both surfaces draw identically.
  static Path buildRoutePath(
    List<Offset> points, {
    required double routeKm,
    double minPointSpacing = 8.0,
  }) {
    if (points.length < 2) return Path();
    if (points.length == 2) {
      return buildArcPath(points.first, points.last, routeKm: routeKm);
    }
    final simplified = _simplifyForDisplay(points, minPointSpacing);
    if (simplified.length == 2) {
      return Path()
        ..moveTo(simplified.first.dx, simplified.first.dy)
        ..lineTo(simplified.last.dx, simplified.last.dy);
    }
    return _smoothThroughMidpoints(simplified);
  }

  /// Drops points closer together than [minSpacing] px (keeping endpoints):
  /// dense GPS tracks otherwise turn corner smoothing into visible jitter.
  static List<Offset> _simplifyForDisplay(
    List<Offset> points,
    double minSpacing,
  ) {
    final result = <Offset>[points.first];
    for (var i = 1; i < points.length - 1; i++) {
      if ((points[i] - result.last).distance >= minSpacing) {
        result.add(points[i]);
      }
    }
    result.add(points.last);
    return result;
  }

  /// Midpoint quadratic smoothing: each interior point becomes a bezier
  /// control, so turns round off while the line stays inside the hull of the
  /// original track and the endpoints stay exact.
  static Path _smoothThroughMidpoints(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final next = points[i + 1];
      final mid = Offset(
        (points[i].dx + next.dx) / 2,
        (points[i].dy + next.dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  /// The stylized route arc — fallback for endpoint-only routes.
  static Path buildArcPath(
    Offset start,
    Offset end, {
    required double routeKm,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt((dx * dx) + (dy * dy));
    if (!length.isFinite || length < 1) {
      return Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);
    }

    final dir = Offset(dx / length, dy / length);
    final perpA = Offset(-dir.dy, dir.dx);
    final perpB = Offset(dir.dy, -dir.dx);
    final perp = perpA.dy <= perpB.dy ? perpA : perpB;

    final strength = (routeKm / 6000).clamp(0.10, 0.22);
    final arcHeight = (length * strength).clamp(14.0, 120.0);
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final control = mid + Offset(perp.dx * arcHeight, perp.dy * arcHeight);

    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }

  void _drawDashedPath(Canvas canvas, Path source, Paint paint) {
    const dashLength = routeDashLength;
    const dashGap = routeDashGap;

    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : dashGap;
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  void _drawAirplane(Canvas canvas, Offset position, Offset directionVector) {
    final image = planeImage;
    if (image == null) return;
    if (!directionVector.dx.isFinite || !directionVector.dy.isFinite) return;
    if (directionVector.distanceSquared == 0) return;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    // Convert direction vector to clockwise bearing from north, which matches
    // an asset that faces "up" in its original orientation.
    final heading = atan2(directionVector.dx, -directionVector.dy);
    canvas.rotate(heading);

    const width = 42.0;
    const height = 56.0;
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst.shift(const Offset(0, 3)),
      Paint()
        ..colorFilter = const ColorFilter.mode(Colors.black38, BlendMode.srcIn)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );

    canvas.restore();
  }

  void _drawDot(Canvas canvas, Offset position) {
    canvas.drawCircle(
      position,
      endpointOuterRadius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      position,
      endpointInnerRadius,
      Paint()..color = routeColor,
    );
  }

  void _drawAirportCodeLabels(
    Canvas canvas,
    Size size,
    Path path,
    Offset start,
    Offset end,
  ) {
    final depCode = flight.departure.displayCode.trim().toUpperCase();
    final arrCode = flight.arrival.displayCode.trim().toUpperCase();
    if (depCode.isEmpty && arrCode.isEmpty) return;

    final pathSamples = _samplePath(path, sampleCount: 100);
    if (depCode.isNotEmpty) {
      _drawAirportCodeLabel(
        canvas,
        size: size,
        anchor: start,
        code: depCode,
        pathSamples: pathSamples,
        isStart: true,
      );
    }
    if (arrCode.isNotEmpty) {
      _drawAirportCodeLabel(
        canvas,
        size: size,
        anchor: end,
        code: arrCode,
        pathSamples: pathSamples,
        isStart: false,
      );
    }
  }

  void _drawAirportCodeLabel(
    Canvas canvas, {
    required Size size,
    required Offset anchor,
    required String code,
    required List<Offset> pathSamples,
    required bool isStart,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: code,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    const hPad = 8.0;
    const vPad = 4.0;
    final labelSize = Size(
      painter.width + (hPad * 2),
      painter.height + (vPad * 2),
    );
    final rect = _pickLabelRect(
      anchor: anchor,
      labelSize: labelSize,
      size: size,
      pathSamples: pathSamples,
      isStart: isStart,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(11));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xB2122235));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0x8896AEC8),
    );
    painter.paint(canvas, Offset(rect.left + hPad, rect.top + vPad));
  }

  Rect _pickLabelRect({
    required Offset anchor,
    required Size labelSize,
    required Size size,
    required List<Offset> pathSamples,
    required bool isStart,
  }) {
    const gap = 12.0;
    final w = labelSize.width;
    final h = labelSize.height;

    final ordered = isStart
        ? <Offset>[
            Offset(anchor.dx - w - gap, anchor.dy + gap),
            Offset(anchor.dx - w - gap, anchor.dy - h - gap),
            Offset(anchor.dx + gap, anchor.dy + gap),
            Offset(anchor.dx + gap, anchor.dy - h - gap),
          ]
        : <Offset>[
            Offset(anchor.dx + gap, anchor.dy + gap),
            Offset(anchor.dx + gap, anchor.dy - h - gap),
            Offset(anchor.dx - w - gap, anchor.dy + gap),
            Offset(anchor.dx - w - gap, anchor.dy - h - gap),
          ];

    Rect? best;
    var bestDistance = -1.0;
    for (final origin in ordered) {
      final clamped = _clampRectToCanvas(
        Rect.fromLTWH(origin.dx, origin.dy, w, h),
        size,
      );
      final intersectsPath = pathSamples.any(
        (p) => clamped.inflate(4).contains(p),
      );
      if (!intersectsPath) return clamped;
      final center = clamped.center;
      final minDistance = pathSamples
          .map((p) => (p - center).distance)
          .reduce(min);
      if (minDistance > bestDistance) {
        bestDistance = minDistance;
        best = clamped;
      }
    }
    return best ??
        _clampRectToCanvas(
          Rect.fromLTWH(anchor.dx + gap, anchor.dy + gap, w, h),
          size,
        );
  }

  Rect _clampRectToCanvas(Rect rect, Size size) {
    const margin = 4.0;
    var left = rect.left;
    var top = rect.top;

    if (left < margin) left = margin;
    if (top < margin) top = margin;
    if (left + rect.width > size.width - margin) {
      left = max(margin, size.width - margin - rect.width);
    }
    if (top + rect.height > size.height - margin) {
      top = max(margin, size.height - margin - rect.height);
    }

    return Rect.fromLTWH(left, top, rect.width, rect.height);
  }

  List<Offset> _samplePath(Path path, {required int sampleCount}) {
    if (sampleCount <= 1) return const [];
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return const [];
    final metric = metrics.first;
    final samples = <Offset>[];
    for (var i = 0; i < sampleCount; i++) {
      final t = i / (sampleCount - 1);
      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent != null) {
        samples.add(tangent.position);
      }
    }
    return samples;
  }
}
