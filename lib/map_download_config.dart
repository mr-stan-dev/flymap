import 'dart:math' as math;

import 'package:flymap/entity/map_detail_level.dart';

class MapDownloadConfig {
  MapDownloadConfig._();

  static const int wayPointDensityKm = 100;
  static const double corridorWidthKm = 160.0;

  static const int minDownloadZoom = 0;
  static const int maxDownloadZoom = 10;
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

  static bool isLongRoute(double distanceKm) => distanceKm > 2500.0;

  static int resolveMaxZoom({
    required double distanceKm,
    required MapDetailLevel detailLevel,
  }) {
    final longRoute = isLongRoute(distanceKm);
    return switch (detailLevel) {
      MapDetailLevel.basic => longRoute ? 9 : 10,
      MapDetailLevel.pro => longRoute ? 10 : 11,
    };
  }

  static double zoomScaleForEstimate(int maxZoom) {
    return math.pow(2, maxZoom - 10).toDouble();
  }
}
