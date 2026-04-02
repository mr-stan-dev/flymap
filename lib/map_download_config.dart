import 'dart:math' as math;

import 'package:flymap/entity/map_detail_level.dart';

/// Route length buckets used by map download zoom and sizing logic.
///
/// Ranges:
/// - [RouteLength.short]: `<= 2500 km`
/// - [RouteLength.mid]: `> 2500 km` and `<= 5000 km`
/// - [RouteLength.long]: `> 5000 km` and `<= 10000 km`
/// - [RouteLength.superLong]: `> 10000 km`
enum RouteLength { short, mid, long, superLong }

class MapDownloadConfig {
  MapDownloadConfig._();

  static const int wayPointDensityKm = 100;
  static const double corridorWidthKm = 320.0;

  static const int minDownloadZoom = 0;
  static const int defaultWorkerCount = 6;
  static const int seaFilterMinZoom = 6;

  static const String mapLayerId = 'ofm_vector';
  static const String mbtilesDirectoryName = 'mbtiles';
  static const String tileUrlTemplate =
      'https://tiles.openfreemap.org/planet/20260304_001001_pt/{z}/{x}/{y}.pbf';

  static const double fallbackDistanceKm = 1000.0;
  static const double estimatedMinMbPer1000Km = 30.0;
  static const double estimatedMaxMbPer1000Km = 50.0;
  static const double estimatedArticleMb = 0.5;

  static RouteLength resolveRouteLength(double distanceKm) {
    if (distanceKm > 10000.0) {
      return RouteLength.superLong;
    }
    if (distanceKm > 5000.0) {
      return RouteLength.long;
    }
    if (distanceKm > 2500.0) {
      return RouteLength.mid;
    }
    return RouteLength.short;
  }

  static int resolveMaxZoom({
    required double distanceKm,
    required MapDetailLevel detailLevel,
  }) {
    final routeLength = resolveRouteLength(distanceKm);
    return switch (detailLevel) {
      MapDetailLevel.basic => switch (routeLength) {
        RouteLength.short => 10,
        RouteLength.mid => 9,
        RouteLength.long => 8,
        RouteLength.superLong => 7,
      },
      MapDetailLevel.pro => switch (routeLength) {
        RouteLength.short => 11,
        RouteLength.mid => 10,
        RouteLength.long => 9,
        RouteLength.superLong => 8,
      },
    };
  }

  static double zoomScaleForEstimate(int maxZoom) {
    return math.pow(2, maxZoom - 10).toDouble();
  }
}
