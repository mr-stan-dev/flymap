import 'dart:math' as math;
import 'package:latlong2/latlong.dart' show LatLng;

class MapTile {
  final int z;
  final int x;
  final int y;
  MapTile(this.z, this.x, this.y);
}

/// Utility class to convert between tile and lat/lon coordinates
class TileUtils {

  /// Converts latitude & longitude to XYZ tile coordinates at a given zoom level
  static MapTile xyzFromLatLon(LatLng latLon, int zoom) {
    final n = math.pow(2, zoom).toDouble();
    final xTile = ((latLon.longitude + 180.0) / 360.0 * n).floor();
    final yTile =
        ((1 -
                    math.log(
                          math.tan(latLon.latitude * math.pi / 180.0) +
                              1 / math.cos(latLon.latitude * math.pi / 180.0),
                        ) /
                        math.pi) /
                2 *
                n)
            .floor();
    return MapTile(zoom, xTile, yTile);
  }

  /// Iterates all tile coords inside polygon for zoom level
  static Iterable<MapTile> tilesForPolygon(
    List<LatLng> polygon,
    int zoom,
  ) sync* {
    print('[VectorTilesDownloader] Computing tiles for zoom $zoom...');
    // Rough approach: iterate over bounding box tiles and include tile if its center in polygon.
    double minLat = polygon.first.latitude;
    double maxLat = polygon.first.latitude;
    double minLon = polygon.first.longitude;
    double maxLon = polygon.first.longitude;
    for (final pnt in polygon) {
      if (pnt.latitude < minLat) minLat = pnt.latitude;
      if (pnt.latitude > maxLat) maxLat = pnt.latitude;
      if (pnt.longitude < minLon) minLon = pnt.longitude;
      if (pnt.longitude > maxLon) maxLon = pnt.longitude;
    }
    final topLeft = xyzFromLatLon(LatLng(maxLat, minLon), zoom);
    final bottomRight = xyzFromLatLon(LatLng(minLat, maxLon), zoom);
    int tileCount = 0;
    for (int x = topLeft.x; x <= bottomRight.x; x++) {
      final minY = math.min(topLeft.y, bottomRight.y);
      final maxY = math.max(topLeft.y, bottomRight.y);
      for (int y = minY; y <= maxY; y++) {
        final intersects = _tileIntersectsPolygon(x, y, zoom, polygon);
        if (intersects) {
          yield MapTile(zoom, x, y);
          tileCount++;
        }
      }
    }
    print('[VectorTilesDownloader] Zoom $zoom: $tileCount tiles selected');
  }

  static LatLng latLonFromTileCenter(int x, int y, int z) {
    final n = math.pow(2, z).toDouble();
    final lonDeg = x / n * 360.0 - 180.0;
    final latRad = math.atan(_sinh(math.pi * (1 - 2 * y / n)));
    final latDeg = latRad * 180.0 / math.pi;
    return LatLng(latDeg, lonDeg);
  }

  static bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;
      final intersect =
          ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) / ((yj - yi) + 1e-12) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  static bool _tileIntersectsPolygon(int x, int y, int z, List<LatLng> poly) {
    // Tile rectangle in lat/lon
    final n = math.pow(2, z).toDouble();
    final west = x / n * 360.0 - 180.0;
    final east = (x + 1) / n * 360.0 - 180.0;
    // Better: use edge computation
    final northLat = latLonFromTileCenter(x, y, z).latitude;
    final southLat = latLonFromTileCenter(x, y + 1, z).latitude;

    // 1. Any polygon vertex inside rect?
    for (final p in poly) {
      if (p.longitude >= west &&
          p.longitude <= east &&
          p.latitude <= northLat &&
          p.latitude >= southLat) {
        return true;
      }
    }

    // 2. Any rect corner inside polygon?
    final corners = [
      LatLng(northLat, west),
      LatLng(northLat, east),
      LatLng(southLat, east),
      LatLng(southLat, west),
    ];
    for (final c in corners) {
      if (_pointInPolygon(c, poly)) return true;
    }

    // 3. Edge intersection
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final p1 = poly[j];
      final p2 = poly[i];
      if (_lineIntersectsRect(p1, p2, west, east, southLat, northLat)) {
        return true;
      }
    }
    return false;
  }

  static bool _lineIntersectsRect(
    LatLng p1,
    LatLng p2,
    double west,
    double east,
    double south,
    double north,
  ) {
    // Liang–Barsky clipping like approach: check if segment intersects any of 4 edges.
    return _segmentsIntersect(
          p1,
          p2,
          LatLng(south, west),
          LatLng(south, east),
        ) || // south edge
        _segmentsIntersect(
          p1,
          p2,
          LatLng(north, west),
          LatLng(north, east),
        ) || // north
        _segmentsIntersect(
          p1,
          p2,
          LatLng(south, west),
          LatLng(north, west),
        ) || // west
        _segmentsIntersect(
          p1,
          p2,
          LatLng(south, east),
          LatLng(north, east),
        ); // east
  }

  static bool _segmentsIntersect(LatLng a1, LatLng a2, LatLng b1, LatLng b2) {
    double cross(double x1, double y1, double x2, double y2) =>
        x1 * y2 - y1 * x2;
    final d1x = a2.longitude - a1.longitude;
    final d1y = a2.latitude - a1.latitude;
    final d2x = b2.longitude - b1.longitude;
    final d2y = b2.latitude - b1.latitude;

    final delta = cross(d1x, d1y, d2x, d2y);
    if (delta.abs() < 1e-12) return false; // Parallel

    final s =
        cross(
          b1.longitude - a1.longitude,
          b1.latitude - a1.latitude,
          d2x,
          d2y,
        ) /
        delta;
    final t =
        cross(
          b1.longitude - a1.longitude,
          b1.latitude - a1.latitude,
          d1x,
          d1y,
        ) /
        delta;
    return s >= 0 && s <= 1 && t >= 0 && t <= 1;
  }
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
