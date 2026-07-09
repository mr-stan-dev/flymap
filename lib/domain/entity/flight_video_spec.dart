import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Camera state for a single flight-video frame.
class CameraPose extends Equatable {
  const CameraPose({
    required this.center,
    required this.zoom,
    required this.pitchDeg,
    required this.bearingDeg,
  });

  /// Camera target. Longitude may be outside [-180, 180]: routes are
  /// longitude-unwrapped so antimeridian crossings stay continuous.
  final LatLng center;
  final double zoom;
  final double pitchDeg;
  final double bearingDeg;

  @override
  List<Object?> get props => [center, zoom, pitchDeg, bearingDeg];
}

enum FlightVideoStage { preparingTiles, rendering, finalizing }

/// Selectable base-map looks for the flight video (Mapbox Static Tiles
/// styles). Declaration order is the selector order; outdoors ("Default")
/// comes first and is the default style.
enum FlightVideoMapStyle {
  outdoors(
    'mapbox/outdoors-v12',
    includesSatelliteImagery: false,
    thumbnailAsset: 'assets/images/map_styles/default.webp',
  ),
  satellite(
    'mapbox/satellite-v9',
    includesSatelliteImagery: true,
    thumbnailAsset: 'assets/images/map_styles/satellite.webp',
  ),
  // "Lè Shine" community style by Nat Slaughter (Mapbox gallery): a pale,
  // restrained monochrome palette. NOTE: it's a community style — if these
  // tiles 404, duplicate it into your own Mapbox account in Studio and paste
  // the resulting `account/styleid` here. Raster tiles bake labels in, so
  // (unlike web) road labels can't be stripped at the layer level.
  shine(
    'mapbox/cj44mfrt20f082snokim4ungi',
    includesSatelliteImagery: false,
    // No dedicated asset yet; the pale default thumbnail stands in.
    thumbnailAsset: 'assets/images/map_styles/default.webp',
  );

  const FlightVideoMapStyle(
    this.styleId, {
    required this.includesSatelliteImagery,
    required this.thumbnailAsset,
  });

  final String styleId;
  final bool includesSatelliteImagery;

  /// Bundled preview square (same artwork the website uses) — a live tile
  /// sample was a plain blue square on ocean routes.
  final String thumbnailAsset;

  /// Mapbox requires Maxar attribution only for satellite imagery.
  String get attribution => includesSatelliteImagery
      ? '© Mapbox © OpenStreetMap © Maxar'
      : '© Mapbox © OpenStreetMap';
}

/// Cooperative cancellation for tile prefetch and the export frame loop.
class FlightVideoCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

class FlightVideoProgress extends Equatable {
  const FlightVideoProgress({required this.stage, required this.fraction});

  final FlightVideoStage stage;

  /// Progress within [stage], 0..1.
  final double fraction;

  @override
  List<Object?> get props => [stage, fraction];
}

/// Output parameters of a flight video.
class FlightVideoSpec extends Equatable {
  const FlightVideoSpec({
    this.width = defaultWidth,
    this.height = defaultHeight,
    this.fps = defaultFps,
    this.renderScale = proRenderScale,
    this.tailHold = defaultTailHold,
    required this.duration,
  });

  /// Duration scales with route length, clamped to a shareable range.
  /// Generous on purpose: a slower plane reads calmer and gives the pins
  /// and regions time to breathe.
  factory FlightVideoSpec.forDistance(
    double distanceKm, {
    double renderScale = proRenderScale,
  }) {
    final km = distanceKm.isFinite && distanceKm > 0 ? distanceKm : 500.0;
    final seconds = (14 + 10 * _log10(1 + km / 300)).clamp(
      minSeconds,
      maxSeconds,
    );
    return FlightVideoSpec(
      renderScale: renderScale,
      duration: Duration(milliseconds: (seconds * 1000).round()),
    );
  }

  static const int defaultWidth = 1080;
  static const int defaultHeight = 1920;

  /// 24 fps reads smooth for map motion and cuts render/encode work by 20%
  /// vs 30 fps.
  static const int defaultFps = 24;

  /// The choreography/renderer works in [width]x[height] logical space; the
  /// exported file is rasterized at [renderScale]. Pro exports at 900x1600,
  /// free at HD 720x1280.
  static const double proRenderScale = 5 / 6;
  static const double freeRenderScale = 2 / 3;

  static const double minSeconds = 16;
  static const double maxSeconds = 40;

  /// Extra time held on the settled summary card after the flight animation
  /// finishes — a frozen tail so viewers can read the route/stats. Appended to
  /// [duration]; the flight itself keeps its pace (see [choreographyTime]).
  static const Duration defaultTailHold = Duration(seconds: 2);

  final int width;
  final int height;
  final int fps;
  final double renderScale;

  /// The animated flight duration (excludes [tailHold]).
  final Duration duration;

  /// Held summary-card time appended after the flight; see [defaultTailHold].
  final Duration tailHold;

  /// Total played/exported length: the flight plus the held summary card.
  Duration get totalDuration => duration + tailHold;

  /// Maps a linear progress `raw in [0, 1]` over [totalDuration] to the
  /// choreography time `t in [0, 1]` the planner/renderer expect. The flight
  /// plays across the first [duration] worth of frames (so it keeps its pace),
  /// then `t` saturates at 1.0 for the [tailHold] — freezing the settled
  /// summary card instead of slowing the whole video down.
  double choreographyTime(double raw) {
    final total = totalDuration.inMicroseconds;
    if (total <= 0) return raw.clamp(0.0, 1.0);
    final active = duration.inMicroseconds / total;
    if (active >= 1.0) return raw.clamp(0.0, 1.0);
    return (raw / active).clamp(0.0, 1.0);
  }

  /// Pixel width of the exported video file (kept even for encoders).
  int get outputWidth => _even((width * renderScale).round());

  /// Pixel height of the exported video file.
  int get outputHeight => _even((height * renderScale).round());

  int get frameCount =>
      max(2, (totalDuration.inMilliseconds * fps / 1000).round());

  static int _even(int v) => v - (v % 2);

  static double _log10(double x) => log(x) / ln10;

  @override
  List<Object?> get props => [
    width,
    height,
    fps,
    renderScale,
    duration,
    tailHold,
  ];
}
