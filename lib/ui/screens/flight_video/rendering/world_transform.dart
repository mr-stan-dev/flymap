import 'dart:math';
import 'dart:ui';

import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Projects between geographic coordinates, camera-centered world pixels and
/// screen pixels for a single [CameraPose].
///
/// "World pixels" are Web-Mercator pixels at the pose's fractional zoom
/// (the full world is `512 * 2^zoom` px), re-centered on the camera so the
/// camera target sits at the world origin and projects to [anchor].
///
/// The "3D" look is the flat map plane tilted away from the viewer:
/// `rotateZ(-bearing)` turns the map course-up, `rotateX(pitch)` tilts it so
/// the top of the screen recedes, and a single perspective entry makes far
/// areas shrink toward a horizon line.
class WorldTransform {
  WorldTransform._({
    required this.pose,
    required this.viewport,
    required this.anchor,
    required this.worldScale,
    required this.cameraWorld,
    required this.canvasMatrix,
    required List<double> homography,
    required List<double>? inverseHomography,
    required this.horizonY,
    required this.mapClipTop,
  }) : _h = homography,
       _hInv = inverseHomography;

  factory WorldTransform.fromPose({
    required CameraPose pose,
    required Size viewport,
    double anchorYFraction = defaultAnchorYFraction,
    double perspectiveDistanceFactor = defaultPerspectiveDistanceFactor,
    double horizonMarginFraction = defaultHorizonMarginFraction,
  }) {
    final anchor = Offset(
      viewport.width / 2,
      viewport.height * anchorYFraction,
    );
    final worldScale = tileSizePx * pow(2.0, pose.zoom).toDouble();
    final cameraWorld = Offset(
      mercXNorm(pose.center.longitude) * worldScale,
      mercYNorm(pose.center.latitude) * worldScale,
    );

    final d = perspectiveDistanceFactor * viewport.height;
    final pitchRad = pose.pitchDeg * pi / 180;
    final bearingRad = pose.bearingDeg * pi / 180;

    // screen = T(anchor) * Perspective * Rx(pitch) * Rz(-bearing) * world
    final perspective = Matrix4.identity()
      ..setEntry(3, 2, -1.0 / d)
      ..rotateX(pitchRad)
      ..rotateZ(-bearingRad);
    final matrix = Matrix4.translationValues(anchor.dx, anchor.dy, 0)
      ..multiply(perspective);

    // The map lives on the z=0 plane, so the 4x4 collapses to a 3x3
    // homography (columns/rows 0, 1 and 3).
    final s = matrix.storage; // column-major: s[col * 4 + row]
    final h = <double>[
      s[0], s[4], s[12], // row 0: m00 m01 m03
      s[1], s[5], s[13], // row 1: m10 m11 m13
      s[3], s[7], s[15], // row 3: m30 m31 m33
    ];

    // Screen row where the tilted map plane vanishes. Above it there is sky.
    final horizonY = pitchRad.abs() < minPitchRadForHorizon
        ? double.negativeInfinity
        : anchor.dy - d / tan(pitchRad.abs());
    // Never draw all the way to the mathematical horizon: ground distance
    // explodes there. Keep a margin and cover it with the sky/haze gradient.
    final double mapClipTop;
    if (horizonY.isFinite) {
      mapClipTop = max(
        0.0,
        horizonY + horizonMarginFraction * (viewport.height - horizonY),
      );
    } else {
      mapClipTop = 0;
    }

    return WorldTransform._(
      pose: pose,
      viewport: viewport,
      anchor: anchor,
      worldScale: worldScale,
      cameraWorld: cameraWorld,
      canvasMatrix: matrix,
      homography: h,
      inverseHomography: _invert3x3(h),
      horizonY: horizonY,
      mapClipTop: mapClipTop,
    );
  }

  static const double tileSizePx = 512;
  static const double maxMercatorLat = 85.05112878;
  static const double defaultAnchorYFraction = 0.62;

  /// Tuned together with [defaultHorizonMarginFraction] so the tilted view
  /// splits roughly 80% map / 20% sky+haze at follow pitch (55 deg).
  static const double defaultPerspectiveDistanceFactor = 0.72;

  /// 0.10 looked great but the deep far-field pushed per-frame tile draws
  /// past what mid-range GPUs rasterize comfortably; 0.14 keeps ~77/23
  /// map/sky at a much lower fill cost.
  static const double defaultHorizonMarginFraction = 0.14;
  static const double minPitchRadForHorizon = 0.01;

  final CameraPose pose;
  final Size viewport;

  /// Screen position of the camera target.
  final Offset anchor;

  /// World size in pixels at the pose zoom (`512 * 2^zoom`).
  final double worldScale;

  /// Camera target in absolute world pixels.
  final Offset cameraWorld;

  /// Full transform for `canvas.transform` over camera-centered world pixels.
  final Matrix4 canvasMatrix;

  final List<double> _h;
  final List<double>? _hInv;

  /// Screen y of the map plane's vanishing line; `-inf` when pitch ~ 0.
  final double horizonY;

  /// Screen y above which the map is not drawn (sky/haze covers it).
  final double mapClipTop;

  /// Absolute world pixels of [p] at this pose's zoom.
  Offset absoluteWorld(LatLng p) => Offset(
    mercXNorm(p.longitude) * worldScale,
    mercYNorm(p.latitude) * worldScale,
  );

  /// Camera-centered world pixels of [p].
  Offset worldOf(LatLng p) => absoluteWorld(p) - cameraWorld;

  /// Screen position of a camera-centered world point.
  Offset projectWorld(Offset world) {
    final w = _h[6] * world.dx + _h[7] * world.dy + _h[8];
    final safeW = w.abs() < 1e-12 ? 1e-12 : w;
    return Offset(
      (_h[0] * world.dx + _h[1] * world.dy + _h[2]) / safeW,
      (_h[3] * world.dx + _h[4] * world.dy + _h[5]) / safeW,
    );
  }

  /// Perspective depth of a camera-centered world point. Points are visible
  /// (in front of the horizon) when this is > 0; 1 at the camera target.
  double perspectiveDepth(Offset world) =>
      _h[6] * world.dx + _h[7] * world.dy + _h[8];

  Offset projectLatLng(LatLng p) => projectWorld(worldOf(p));

  /// Camera-centered world point under screen position [screen], or null at
  /// or beyond the horizon.
  Offset? unprojectScreen(Offset screen) {
    final inv = _hInv;
    if (inv == null) return null;
    final w = inv[6] * screen.dx + inv[7] * screen.dy + inv[8];
    if (w <= 1e-12) return null;
    return Offset(
      (inv[0] * screen.dx + inv[1] * screen.dy + inv[2]) / w,
      (inv[3] * screen.dx + inv[4] * screen.dy + inv[5]) / w,
    );
  }

  LatLng latLngOfWorld(Offset world) {
    final abs = world + cameraWorld;
    return LatLng(
      latFromMercYNorm(abs.dy / worldScale),
      lonFromMercXNorm(abs.dx / worldScale),
    );
  }

  /// Normalized mercator x for an (optionally unwrapped) longitude. Values
  /// outside [0, 1] represent worlds beyond the antimeridian.
  static double mercXNorm(double lon) => (lon + 180) / 360;

  static double mercYNorm(double lat) {
    final clamped = lat.clamp(-maxMercatorLat, maxMercatorLat);
    final phi = clamped * pi / 180;
    return 0.5 - log(tan(pi / 4 + phi / 2)) / (2 * pi);
  }

  static double lonFromMercXNorm(double x) => x * 360 - 180;

  static double latFromMercYNorm(double y) {
    final n = pi * (1 - 2 * y);
    return atan((exp(n) - exp(-n)) / 2) * 180 / pi;
  }

  static List<double>? _invert3x3(List<double> m) {
    final a = m[0], b = m[1], c = m[2];
    final d = m[3], e = m[4], f = m[5];
    final g = m[6], h = m[7], i = m[8];

    final det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
    if (det.abs() < 1e-18) return null;
    final invDet = 1 / det;
    return <double>[
      (e * i - f * h) * invDet,
      (c * h - b * i) * invDet,
      (b * f - c * e) * invDet,
      (f * g - d * i) * invDet,
      (a * i - c * g) * invDet,
      (c * d - a * f) * invDet,
      (d * h - e * g) * invDet,
      (b * g - a * h) * invDet,
      (a * e - b * d) * invDet,
    ];
  }
}
