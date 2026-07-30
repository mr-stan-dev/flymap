import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Synthetic-but-plausible cloud forecast for demo surfaces (onboarding
/// weather payoff, the free-flight teaser): a hand-authored story curve
/// along a projected route, rasterized by the real [CloudFieldBuilder]
/// pipeline. Fully deterministic, zero network — never mixes with a real
/// forecast, so demo surfaces must label it as an example.
class DemoCloudStory {
  const DemoCloudStory({
    required this.hiddenAnchors,
    required this.rainCenter,
    required this.rainWidth,
    required this.rainAmplitudeMm,
  });

  /// Route-agnostic default for teasers: broken clouds after takeoff,
  /// clear mid-flight, a rain-shaded deck building before landing —
  /// every verdict flavor visible within one plane pass.
  static const DemoCloudStory generic = DemoCloudStory(
    hiddenAnchors: [
      (0.0, 45),
      (0.15, 30),
      (0.35, 12),
      (0.55, 18),
      (0.7, 55),
      (0.82, 80),
      (1.0, 60),
    ],
    rainCenter: 0.85,
    rainWidth: 0.08,
    rainAmplitudeMm: 2.2,
  );

  /// Any fixed instant works — the forecast is fully synthetic; constants
  /// keep every frame deterministic.
  static final DateTime defaultWindowStart = DateTime.utc(2026, 5, 15, 9);
  static final DateTime defaultWindowEnd = defaultWindowStart.add(
    const Duration(hours: 2, minutes: 20),
  );

  /// (routeProgress, hidden-ground %) anchor points of the cloud story.
  final List<(double, double)> hiddenAnchors;
  final double rainCenter;
  final double rainWidth;
  final double rainAmplitudeMm;

  /// Samples + their viewport-space positions for [CloudFieldBuilder]:
  /// 13 corridor stops along [projectedRoute] plus a 6x6 grid over the
  /// square viewport, keyed to the nearest corridor stop so off-route
  /// clouds tell the same story with lateral variety.
  ({List<RouteCloudSample> samples, List<Offset> positions}) build({
    required List<Offset> projectedRoute,
    required double viewportSize,
    DateTime? windowStart,
    DateTime? windowEnd,
  }) {
    final start = windowStart ?? defaultWindowStart;
    final end = windowEnd ?? defaultWindowEnd;
    final samples = <RouteCloudSample>[];
    final positions = <Offset>[];

    const corridorCount = 13;
    for (var i = 0; i < corridorCount; i++) {
      final progress = i / (corridorCount - 1);
      final index = (progress * (projectedRoute.length - 1)).round();
      samples.add(
        _sample(
          progress: progress,
          phase: progress * 5.3,
          amplitude: 0.22,
          windowStart: start,
          windowEnd: end,
        ),
      );
      positions.add(projectedRoute[index]);
    }

    for (var gx = 0; gx < 6; gx++) {
      for (var gy = 0; gy < 6; gy++) {
        final position = Offset(
          -30 + gx * (viewportSize + 60) / 5,
          -30 + gy * (viewportSize + 60) / 5,
        );
        var nearest = 0.0;
        var bestD2 = double.infinity;
        for (var i = 0; i < corridorCount; i++) {
          final index =
              (i / (corridorCount - 1) * (projectedRoute.length - 1)).round();
          final d = projectedRoute[index] - position;
          final d2 = d.dx * d.dx + d.dy * d.dy;
          if (d2 < bestD2) {
            bestD2 = d2;
            nearest = i / (corridorCount - 1);
          }
        }
        final lateral = math.sin(position.dx * 0.013 + position.dy * 0.017);
        samples.add(
          _sample(
            progress: (nearest + 0.06 * lateral).clamp(0.0, 1.0),
            phase: position.dx * 0.02 + position.dy * 0.011,
            amplitude: 0.3,
            windowStart: start,
            windowEnd: end,
          ),
        );
        positions.add(position);
      }
    }
    return (samples: samples, positions: positions);
  }

  double _hiddenBase(double progress) {
    for (var i = 1; i < hiddenAnchors.length; i++) {
      if (progress <= hiddenAnchors[i].$1) {
        final (p0, v0) = hiddenAnchors[i - 1];
        final (p1, v1) = hiddenAnchors[i];
        final t = ((progress - p0) / (p1 - p0)).clamp(0.0, 1.0);
        return v0 + (v1 - v0) * t;
      }
    }
    return hiddenAnchors.last.$2;
  }

  double _rainBase(double progress) {
    final d = (progress - rainCenter) / rainWidth;
    return rainAmplitudeMm * math.exp(-d * d);
  }

  /// One synthetic sample: overhead values from the story curve, plus a
  /// 4-slice timeline that wobbles the deck so the field visibly evolves
  /// (and the rain builds) while the plane flies.
  RouteCloudSample _sample({
    required double progress,
    required double phase,
    required double amplitude,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final base = _hiddenBase(progress);
    final rain = _rainBase(progress);
    final windowSeconds = windowEnd.difference(windowStart).inSeconds;
    final slices = <CloudTimeSlice>[
      for (var i = 0; i < 4; i++)
        () {
          final t = i / 3;
          final wobble = 1 + amplitude * math.sin(t * math.pi * 1.6 + phase);
          return CloudTimeSlice(
            timeUtc: windowStart.add(
              Duration(seconds: (windowSeconds * t).round()),
            ),
            cloudLowPercent: (base * 0.6 * wobble).clamp(0.0, 100.0),
            cloudMidPercent: (base * 0.4 * wobble).clamp(0.0, 100.0),
            cloudHighPercent: (12 + 10 * math.sin(phase + t * 4)).clamp(
              0.0,
              100.0,
            ),
            precipitationMm: rain * (0.5 + 0.9 * t),
          );
        }(),
    ];
    return RouteCloudSample(
      routeProgress: progress,
      // Positions are supplied alongside; the field builder never reads
      // latLon, so any value satisfies the entity.
      latLon: const LatLng(0, 0),
      timeUtc: windowStart.add(
        Duration(seconds: (windowSeconds * progress).round()),
      ),
      cloudLowPercent: base * 0.6,
      cloudMidPercent: base * 0.4,
      cloudHighPercent: 14,
      precipitationMm: rain,
      timeline: slices,
    );
  }
}
