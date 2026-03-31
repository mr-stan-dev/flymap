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
}
