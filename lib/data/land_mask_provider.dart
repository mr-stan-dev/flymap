import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../logger.dart';

/// Provider for determining if geographic areas contain land.
///
/// It prefers a real coastline mask parsed from simplified Natural Earth data
/// and falls back to coarse continent heuristics if the mask is unavailable.
class LandMaskProvider {
  static const String _landMaskAssetPath = 'assets/data/ne_110m_land.geojson';
  static final Logger _logger = Logger('LandMaskProvider');

  static final List<_LandPolygon> _sharedLandPolygons = [];
  static Future<void>? _sharedInitFuture;
  static bool _sharedMaskLoaded = false;

  // Simple cache for land checks with coarse quantization
  final Map<String, bool> _landPointCache = {};

  // Grid sampling across a tile (e.g. 3x3)
  final int sampleGridSize;

  // Quantization resolution for cache (degrees)
  final double cacheResolutionDeg;

  LandMaskProvider({this.sampleGridSize = 3, this.cacheResolutionDeg = 0.25});

  /// Loads coastline polygons once per process.
  Future<void> ensureInitialized() async {
    if (_sharedInitFuture != null) {
      await _sharedInitFuture;
      return;
    }
    _sharedInitFuture = _initializeSharedMask();
    await _sharedInitFuture;
  }

  static Future<void> _initializeSharedMask() async {
    try {
      final raw = await rootBundle.loadString(_landMaskAssetPath);
      final count = _parseGeoJsonIntoSharedPolygons(raw);
      _sharedMaskLoaded = count > 0;
      if (_sharedMaskLoaded) {
        _logger.log('Loaded coastline mask polygons: $count');
      } else {
        _logger.log(
          'Coastline mask parsed with zero polygons. Falling back to heuristics.',
        );
      }
    } catch (e) {
      _sharedMaskLoaded = false;
      _logger.error(
        'Failed to load coastline mask asset ($_landMaskAssetPath). '
        'Falling back to heuristics: $e',
      );
    }
  }

  static int _parseGeoJsonIntoSharedPolygons(String rawJson) {
    _sharedLandPolygons.clear();

    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) return 0;
    final features = decoded['features'];
    if (features is! List) return 0;

    for (final feature in features) {
      if (feature is! Map) continue;
      final geometry = feature['geometry'];
      if (geometry is! Map) continue;

      final type = (geometry['type'] ?? '').toString();
      final coordinates = geometry['coordinates'];

      if (type == 'Polygon') {
        _addPolygonFromCoordinates(coordinates);
      } else if (type == 'MultiPolygon' && coordinates is List) {
        for (final polygonCoordinates in coordinates) {
          _addPolygonFromCoordinates(polygonCoordinates);
        }
      }
    }
    return _sharedLandPolygons.length;
  }

  static void _addPolygonFromCoordinates(dynamic polygonCoordinates) {
    if (polygonCoordinates is! List || polygonCoordinates.isEmpty) return;

    // GeoJSON Polygon coordinates = [ exteriorRing, hole1, ... ]
    // For sea filtering, exterior ring is sufficient and faster.
    final exteriorRing = polygonCoordinates.first;
    if (exteriorRing is! List || exteriorRing.length < 3) return;

    final points = <_LonLat>[];
    for (final rawPoint in exteriorRing) {
      if (rawPoint is! List || rawPoint.length < 2) continue;
      final lon = (rawPoint[0] as num?)?.toDouble();
      final lat = (rawPoint[1] as num?)?.toDouble();
      if (lon == null || lat == null || lon.isNaN || lat.isNaN) continue;
      points.add(_LonLat(lat: lat, lon: lon));
    }
    if (points.length < 3) return;
    _sharedLandPolygons.add(_LandPolygon.fromPoints(points));
  }

  /// Check if a tile (defined by bounds) contains any land.
  ///
  /// [bounds] - Tile bounds as [minLat, minLon, maxLat, maxLon]
  /// Returns true if the tile contains land, false if it's ocean only
  bool tileContainsLand(List<double> bounds) {
    if (bounds.length != 4) return false;

    final minLat = bounds[0];
    final minLon = bounds[1];
    final maxLat = bounds[2];
    final maxLon = bounds[3];

    // Multi-sample grid within tile to reduce misclassification
    final samples = sampleGridSize < 1 ? 1 : sampleGridSize;
    if (samples == 1) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLon = (minLon + maxLon) / 2;
      return _isLandPointCached(centerLat, centerLon);
    }

    final latStep = (maxLat - minLat) / (samples - 1);
    final lonStep = (maxLon - minLon) / (samples - 1);

    for (int i = 0; i < samples; i++) {
      final lat = i == samples - 1 ? maxLat : minLat + i * latStep;
      for (int j = 0; j < samples; j++) {
        final lon = j == samples - 1 ? maxLon : minLon + j * lonStep;
        if (_isLandPointCached(lat, lon)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if a point is over land.
  bool pointIsOverLand(double lat, double lon) {
    return _isLandPointCached(lat, lon);
  }

  /// Check if a corridor polygon contains land.
  bool corridorContainsLand(List<LatLng> corridorPolygon) {
    if (corridorPolygon.isEmpty) return false;

    // Check if any point in the corridor is over land
    for (final point in corridorPolygon) {
      if (_isLandPointCached(point.latitude, point.longitude)) {
        return true;
      }
    }

    // Also check the bounding box center
    final bounds = _calculateBounds(corridorPolygon);
    final centerLat = (bounds[0] + bounds[2]) / 2;
    final centerLon = (bounds[1] + bounds[3]) / 2;

    return _isLandPointCached(centerLat, centerLon);
  }

  /// Calculate bounding box for a polygon
  List<double> _calculateBounds(List<LatLng> polygon) {
    if (polygon.isEmpty) return [0, 0, 0, 0];

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLon = double.infinity;
    double maxLon = -double.infinity;

    for (final point in polygon) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLon = min(minLon, point.longitude);
      maxLon = max(maxLon, point.longitude);
    }

    return [minLat, minLon, maxLat, maxLon];
  }

  /// Cached land check with quantized coordinates
  bool _isLandPointCached(double lat, double lon) {
    final qLat = (lat / cacheResolutionDeg).round() * cacheResolutionDeg;
    final qLon = (lon / cacheResolutionDeg).round() * cacheResolutionDeg;
    final modePrefix = _sharedMaskLoaded ? 'coast' : 'heur';
    final key =
        '$modePrefix:${qLat.toStringAsFixed(2)}:${qLon.toStringAsFixed(2)}';
    final cached = _landPointCache[key];
    if (cached != null) return cached;

    final result = _isLandPoint(qLat, qLon);
    _landPointCache[key] = result;
    return result;
  }

  bool _isLandPoint(double lat, double lon) {
    if (_sharedMaskLoaded) {
      return _isLandPointUsingCoastlineMask(lat, lon);
    }
    return _isLandPointHeuristic(lat, lon);
  }

  bool _isLandPointUsingCoastlineMask(double lat, double lon) {
    final normalizedLon = _normalizeLongitude(lon);
    for (final polygon in _sharedLandPolygons) {
      if (!polygon.mightContain(lat, normalizedLon)) {
        continue;
      }
      if (_pointInPolygon(lat, normalizedLon, polygon.points)) {
        return true;
      }
    }
    return false;
  }

  bool _pointInPolygon(double lat, double lon, List<_LonLat> points) {
    var inside = false;
    for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
      final xi = points[i].lon;
      final yi = points[i].lat;
      final xj = points[j].lon;
      final yj = points[j].lat;

      final intersects =
          ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / ((yj - yi) + 1e-12) + xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  /// Coarse fallback heuristics used when mask data is unavailable.
  bool _isLandPointHeuristic(double lat, double lon) {
    // Normalize longitude to -180 to 180
    lon = _normalizeLongitude(lon);

    // Major continental landmasses with more precise boundaries
    final continents = [
      // North America (including US East Coast)
      _Continent(25.0, 75.0, -170.0, -50.0, 'North America'),

      // South America
      _Continent(-55.0, 15.0, -85.0, -35.0, 'South America'),

      // Europe
      _Continent(35.0, 75.0, -10.0, 40.0, 'Europe'),

      // Africa
      _Continent(-35.0, 35.0, -20.0, 50.0, 'Africa'),

      // Asia (main)
      _Continent(10.0, 75.0, 40.0, 180.0, 'Asia Main'),

      // Asia (Alaska extension)
      _Continent(10.0, 75.0, -180.0, -60.0, 'Asia Alaska'),

      // Australia
      _Continent(-45.0, -10.0, 110.0, 155.0, 'Australia'),

      // Greenland
      _Continent(60.0, 85.0, -75.0, -10.0, 'Greenland'),
    ];

    // Check if point is within any continent
    for (final continent in continents) {
      if (continent.contains(lat, lon)) {
        return true;
      }
    }

    // Major islands
    final islands = [
      _Island(35.0, 45.0, 130.0, 145.0, 'Japan'),
      _Island(1.0, 6.0, 95.0, 105.0, 'Sumatra'),
      _Island(-9.0, -8.0, 115.0, 116.0, 'Bali'),
      _Island(20.0, 22.0, -158.0, -154.0, 'Hawaii'),
      _Island(-41.0, -34.0, 165.0, 179.0, 'New Zealand'),
      _Island(25.0, 30.0, -85.0, -80.0, 'Florida'),
      _Island(40.0, 45.0, -75.0, -65.0, 'Northeast US'),
    ];

    for (final island in islands) {
      if (island.contains(lat, lon)) {
        return true;
      }
    }

    return false;
  }

  /// Normalize longitude to -180 to 180 range
  double _normalizeLongitude(double lon) {
    final normalized = ((lon + 180.0) % 360.0 + 360.0) % 360.0 - 180.0;
    return normalized == -180.0 ? 180.0 : normalized;
  }

  /// Get a list of tiles that contain land from a tile grid.
  ///
  /// [minLat, minLon, maxLat, maxLon] - Bounding box
  /// [zoom] - Zoom level
  /// Returns list of tile coordinates [x, y] that contain land
  List<List<int>> getLandTiles(
    double minLat,
    double minLon,
    double maxLat,
    double maxLon,
    int zoom,
  ) {
    final landTiles = <List<int>>[];

    // Convert bounds to tile coordinates
    final minTile = _latLonToTile(minLat, minLon, zoom);
    final maxTile = _latLonToTile(maxLat, maxLon, zoom);

    for (int x = minTile[0]; x <= maxTile[0]; x++) {
      for (int y = minTile[1]; y <= maxTile[1]; y++) {
        // Convert tile coordinates back to bounds
        final tileBounds = _tileToBounds(x, y, zoom);

        if (tileContainsLand(tileBounds)) {
          landTiles.add([x, y]);
        }
      }
    }

    return landTiles;
  }

  /// Convert lat/lon to tile coordinates
  List<int> _latLonToTile(double lat, double lon, int zoom) {
    final n = pow(2, zoom);
    final xtile = ((lon + 180) / 360 * n).floor();
    final ytile =
        ((1 - log(tan(radians(lat)) + 1 / cos(radians(lat))) / pi) / 2 * n)
            .floor();
    return [xtile, ytile];
  }

  /// Convert tile coordinates to bounds
  List<double> _tileToBounds(int x, int y, int zoom) {
    final n = pow(2, zoom);
    final west = x / n * 360 - 180;
    final east = (x + 1) / n * 360 - 180;
    final north =
        atan((exp(pi * (1 - 2 * y / n)) - exp(-pi * (1 - 2 * y / n))) / 2) *
        180 /
        pi;
    final south =
        atan(
          (exp(pi * (1 - 2 * (y + 1) / n)) - exp(-pi * (1 - 2 * (y + 1) / n))) /
              2,
        ) *
        180 /
        pi;
    return [south, west, north, east];
  }

  /// Convert degrees to radians
  double radians(double degrees) => degrees * pi / 180;
}

class _LonLat {
  const _LonLat({required this.lat, required this.lon});

  final double lat;
  final double lon;
}

class _LandPolygon {
  const _LandPolygon({
    required this.points,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  factory _LandPolygon.fromPoints(List<_LonLat> points) {
    var minLat = double.infinity;
    var maxLat = -double.infinity;
    var minLon = double.infinity;
    var maxLon = -double.infinity;
    for (final point in points) {
      if (point.lat < minLat) minLat = point.lat;
      if (point.lat > maxLat) maxLat = point.lat;
      if (point.lon < minLon) minLon = point.lon;
      if (point.lon > maxLon) maxLon = point.lon;
    }
    return _LandPolygon(
      points: points,
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );
  }

  final List<_LonLat> points;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  bool mightContain(double lat, double lon) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }
}

/// Helper class for continent definitions
class _Continent {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final String name;

  _Continent(this.minLat, this.maxLat, this.minLon, this.maxLon, this.name);

  bool contains(double lat, double lon) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }
}

/// Helper class for island definitions
class _Island {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final String name;

  _Island(this.minLat, this.maxLat, this.minLon, this.maxLon, this.name);

  bool contains(double lat, double lon) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }
}
