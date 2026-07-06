import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:flymap/ui/screens/flight_video/rendering/route_path_model.dart';
import 'package:flymap/ui/screens/flight_video/rendering/world_transform.dart';
import 'package:latlong2/latlong.dart';

/// Produces the camera pose and animation values for every normalized time
/// `t in [0, 1]` of a flight video.
///
/// The choreography is one continuous piecewise function (no per-phase state)
/// built from eased keyframes, so phase transitions cannot pop:
/// - 0.00-0.15 overview: top-down, route line draws itself
/// - 0.15-0.80 flight: dive to follow zoom, tilt, chase the plane north-up
/// - 0.80-1.00 outro: pull back to the full route, stats overlay fades in
///
/// The camera never rotates (bearing stays 0 / north-up): the plane sprite
/// rotates along its track instead. This also keeps per-frame tile sets
/// stable, which matters for decode churn.
class CameraPathPlanner {
  CameraPathPlanner({
    required this.route,
    required this.spec,
    EdgeInsets overviewPadding = defaultOverviewPadding,
  }) : _viewport = Size(spec.width.toDouble(), spec.height.toDouble()) {
    _fitOverview(overviewPadding);
    _followZoom = _initialFollowZoom();
    _buildKeyframes();
  }

  static const EdgeInsets defaultOverviewPadding = EdgeInsets.fromLTRB(
    140,
    320,
    140,
    480,
  );

  static const double overviewEnd = 0.15;
  static const double flightEnd = 0.80;

  /// From here to t=1 every frame is pixel-identical: the camera keys settle
  /// by 0.91, the landing pulse ends at 0.89, the plane vanished by ~0.84 and
  /// the stats card finishes fading exactly here. The exporter renders the
  /// first tail frame once and reuses its pixels for the rest.
  static const double staticTailStart = 0.94;
  static const double _diveEnd = 0.2475; // overviewEnd + 0.65 * 0.15
  static const double _pitchUpEnd = 0.26;
  static const double _zoomHoldEnd = 0.748;
  static const double _pitchHoldEnd = 0.78;
  static const double _lookAhead = 0.02;

  /// Follow pitch for a compact/tall route — the full dramatic tilt.
  static const double followPitchDeg = 55;

  /// Follow pitch for a very wide (mostly east-west) route. Wide routes fit
  /// width-first and leave vertical slack that the tilt fills with sky —
  /// dead space that looks especially poor over satellite imagery. At this
  /// pitch the horizon sits at ~3% from the top (tucked behind the header),
  /// so the frame is essentially all map. See [_adaptFollowPitch].
  static const double _minWideFollowPitch = 44;
  static const double _minOverviewZoom = 1.5;
  static const double _maxOverviewZoom = 9.0;
  static const double _maxFollowZoom = 10.0;

  /// How far the camera dives below the overview. Small on purpose: it keeps
  /// the apparent plane speed gentle and lets the whole video render from a
  /// single tile level (no tile swapping during zoom transitions).
  static const double followZoomDelta = 1.6;

  /// The one raster tile level used for the entire video, biased toward the
  /// follow phase so the money shot stays sharp (<=1.8x upscale) while the
  /// overview shows slightly minified tiles (mipmapped, looks fine).
  static const double _tileLevelBias = 0.8;
  static const int minTileLevel = 2;

  final RoutePathModel route;
  final FlightVideoSpec spec;
  final Size _viewport;

  late LatLng _overviewCenter;
  late LatLng _outroCenter;
  late double _overviewZoom;
  late double _followZoom;
  late double _effectiveFollowPitch;
  late _Keyframes _zoomKeys;
  late _Keyframes _pitchKeys;
  late _Keyframes _followWeightKeys;
  late _Keyframes _overviewLiftKeys;
  int _tileLevelDrop = 0;

  /// The summary card sits at the bottom, so the outro overview frames the
  /// whole route into the upper part: its mid-point lands this far down from
  /// the top (0.35 => route in the top ~35%, card clear below).
  static const double _outroRouteTopFraction = 0.35;

  double get overviewZoom => _overviewZoom;

  double get followZoom => _followZoom;

  /// The follow-phase pitch actually used (adapted down for wide routes).
  double get followPitch => _effectiveFollowPitch;

  LatLng get overviewCenter => _overviewCenter;

  /// The single tile level every frame of this video renders from.
  int get tileLevel => max(
    minTileLevel,
    (_overviewZoom + _tileLevelBias).round() - _tileLevelDrop,
  );

  /// Drops the video to a coarser tile level (roughly 3-4x fewer tiles).
  /// Returns false once the floor is reached.
  bool lowerTileLevel() {
    if (tileLevel <= minTileLevel) return false;
    _tileLevelDrop++;
    return true;
  }

  CameraPose poseAt(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final weight = _followWeightKeys.evaluate(clamped);
    final target = route.pointAt(
      min(1.0, planeProgressAt(clamped) + _lookAhead),
    );
    // The overview the camera settles into eases from centred (intro/flight)
    // to the top-framed outro anchor, in step with the pitch-down and
    // zoom-out — so the pitched follow rises straight into the top overview
    // as one motion, no separate push once it has settled.
    final overviewLift = _overviewLiftKeys.evaluate(clamped);
    final overviewAnchor = overviewLift <= 0
        ? _overviewCenter
        : LatLng(
            _lerp(_overviewCenter.latitude, _outroCenter.latitude, overviewLift),
            _lerp(
              _overviewCenter.longitude,
              _outroCenter.longitude,
              overviewLift,
            ),
          );
    final center = weight <= 0
        ? overviewAnchor
        : LatLng(
            _lerp(overviewAnchor.latitude, target.latitude, weight),
            _lerp(overviewAnchor.longitude, target.longitude, weight),
          );

    return CameraPose(
      center: center,
      zoom: _zoomKeys.evaluate(clamped),
      pitchDeg: _pitchKeys.evaluate(clamped),
      bearingDeg: 0,
    );
  }

  /// Plane position along the route, in normalized arc length.
  double planeProgressAt(double t) {
    if (t <= overviewEnd) return 0;
    if (t >= flightEnd) return 1;
    return easeInOutSine((t - overviewEnd) / (flightEnd - overviewEnd));
  }

  /// Departure marker pop-in scale (overshoots slightly above 1).
  double depMarkerScaleAt(double t) => _pop(t, start: 0.01, duration: 0.04);

  /// Arrival marker pop-in scale, once the route line reaches it.
  double arrMarkerScaleAt(double t) => _pop(t, start: 0.125, duration: 0.04);

  /// Outro stats card opacity.
  double statsOverlayOpacityAt(double t) {
    const start = 0.88;
    const end = staticTailStart;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return easeInOutCubic((t - start) / (end - start));
  }

  WorldTransform transformAt(double t) =>
      WorldTransform.fromPose(pose: poseAt(t), viewport: _viewport);

  void _fitOverview(EdgeInsets padding) {
    final points = route.samplePoints;
    var minX = double.infinity, maxX = double.negativeInfinity;
    var minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in points) {
      final x = WorldTransform.mercXNorm(p.longitude);
      final y = WorldTransform.mercYNorm(p.latitude);
      minX = min(minX, x);
      maxX = max(maxX, x);
      minY = min(minY, y);
      maxY = max(maxY, y);
    }
    final spanX = max(1e-9, maxX - minX);
    final spanY = max(1e-9, maxY - minY);
    final availW = max(1.0, _viewport.width - padding.horizontal);
    final availH = max(1.0, _viewport.height - padding.vertical);

    final zoomX = _log2(availW / (WorldTransform.tileSizePx * spanX));
    final zoomY = _log2(availH / (WorldTransform.tileSizePx * spanY));
    _overviewZoom = min(
      zoomX,
      zoomY,
    ).clamp(_minOverviewZoom, _maxOverviewZoom);

    // zoomY - zoomX is how many extra zoom levels the height could take once
    // the width has limited the fit. A portrait viewport gives even a square
    // route some of this, so measure the slack RELATIVE to that baseline:
    // what's left is genuine east-west wideness (the sky-heavy case).
    final viewportBias = _log2(availH / availW);
    _effectiveFollowPitch = _adaptFollowPitch((zoomY - zoomX) - viewportBias);

    final worldScale =
        WorldTransform.tileSizePx * pow(2.0, _overviewZoom).toDouble();
    final centerX =
        (minX + maxX) / 2 + (padding.right - padding.left) / (2 * worldScale);
    final centerY =
        (minY + maxY) / 2 + (padding.bottom - padding.top) / (2 * worldScale);
    _overviewCenter = LatLng(
      WorldTransform.latFromMercYNorm(centerY),
      WorldTransform.lonFromMercXNorm(centerX),
    );

    // Outro framing: same horizontal, but the route mid-point pulled up so it
    // projects at [_outroRouteTopFraction] of the height (top-down, so
    // screen-Y maps linearly to world-Y at the overview scale).
    final outroCenterY = (minY + maxY) / 2 +
        (0.5 - _outroRouteTopFraction) * _viewport.height / worldScale;
    _outroCenter = LatLng(
      WorldTransform.latFromMercYNorm(outroCenterY),
      WorldTransform.lonFromMercXNorm(centerX),
    );
  }

  double _initialFollowZoom() =>
      min(_maxFollowZoom, _overviewZoom + followZoomDelta);

  /// Maps a route's east-west wideness (fit width-slack minus the viewport's
  /// own bias) to a follow pitch: none for compact/tall routes (full
  /// [followPitchDeg] tilt), easing to [_minWideFollowPitch] for very wide
  /// ones so the tilt shows map instead of a big sky band.
  static double _adaptFollowPitch(double extraWide) {
    final tWide = ((extraWide - 0.3) / (1.6 - 0.3)).clamp(0.0, 1.0);
    return followPitchDeg - (followPitchDeg - _minWideFollowPitch) * tWide;
  }

  void _buildKeyframes() {
    final ov = _overviewZoom;
    final zf = _followZoom;
    _zoomKeys = _Keyframes(const [
      0,
      overviewEnd,
      _diveEnd,
      _zoomHoldEnd,
      0.91,
      1,
    ], [ov + 0.15, ov, zf, zf, ov, ov]);
    _pitchKeys = _Keyframes(
      const [0, overviewEnd, _pitchUpEnd, _pitchHoldEnd, 0.90, 1],
      [0, 0, _effectiveFollowPitch, _effectiveFollowPitch, 0, 0],
    );
    _followWeightKeys = _Keyframes(
      const [0, overviewEnd, _diveEnd, _zoomHoldEnd, 0.905, 1],
      const [0, 0, 1, 1, 0, 0],
    );
    // Overview reframing runs concurrently with the pitch-down (0.78 -> 0.90)
    // and follow-weight unwind (settles by 0.905), reaching the top framing
    // as the camera finishes going top-down — one continuous move.
    _overviewLiftKeys = _Keyframes(
      const [0, _pitchHoldEnd, 0.905, 1],
      const [0, 0, 1, 1],
    );
  }

  double _pop(double t, {required double start, required double duration}) {
    if (t <= start) return 0;
    final u = ((t - start) / duration).clamp(0.0, 1.0);
    return _easeOutBack(u);
  }

  static double easeInOutCubic(double u) {
    final x = u.clamp(0.0, 1.0);
    return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3).toDouble() / 2;
  }

  static double easeInOutSine(double u) {
    final x = u.clamp(0.0, 1.0);
    return (1 - cos(pi * x)) / 2;
  }

  static double _easeOutBack(double u) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final x = u - 1;
    return 1 + c3 * x * x * x + c1 * x * x;
  }

  static double _lerp(double a, double b, double f) => a + (b - a) * f;

  static double _log2(double x) => log(x) / ln2;
}

/// Piecewise keyframe curve with ease-in-out-cubic segments. The easing has
/// zero slope at every keyframe, so holds blend smoothly into ramps.
class _Keyframes {
  _Keyframes(this.times, this.values)
    : assert(times.length == values.length),
      assert(times.length >= 2);

  final List<double> times;
  final List<double> values;

  double evaluate(double t) {
    if (t <= times.first) return values.first;
    if (t >= times.last) return values.last;
    var i = 0;
    while (i < times.length - 2 && t > times[i + 1]) {
      i++;
    }
    final span = max(1e-12, times[i + 1] - times[i]);
    final u = CameraPathPlanner.easeInOutCubic((t - times[i]) / span);
    return values[i] + (values[i + 1] - values[i]) * u;
  }
}
