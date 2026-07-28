import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

const double staticShareMapWidth = 540;
const double staticShareMapHeight = 800;
const double staticShareMapPadding = 80;

/// Square variant used by the weather map card — identical framing for
/// horizontal and vertical routes, and less vertical space than portrait.
const double staticWeatherMapSize = 540;
const int maxStaticRoutePoints = 120;
const double _tileSize = 512;
const double _maxLat = 85.05112878;

class StaticMapViewport {
  const StaticMapViewport({
    required this.center,
    required this.zoom,
    required this.width,
    required this.height,
  });

  final LatLng center;
  final double zoom;
  final double width;
  final double height;
}

class ProjectedPoint {
  const ProjectedPoint({
    required this.x,
    required this.y,
    required this.lat,
    required this.lon,
  });

  final double x;
  final double y;
  final double lat;
  final double lon;

  Offset toOffset() => Offset(x, y);
}

class StaticRouteMap {
  static double _clampLat(double lat) {
    return max(-_maxLat, min(_maxLat, lat));
  }

  static double _normalizeLon(double lon) {
    double next = lon;
    while (next > 180) {
      next -= 360;
    }
    while (next < -180) {
      next += 360;
    }
    return next;
  }

  static List<LatLng> _sampleRoutePoints(List<LatLng> points) {
    if (points.length <= maxStaticRoutePoints) return points;
    final result = <LatLng>[];
    final lastIndex = points.length - 1;
    for (int i = 0; i < maxStaticRoutePoints; i++) {
      final index = (i / (maxStaticRoutePoints - 1) * lastIndex).round();
      result.add(points[index]);
    }
    return result;
  }

  static double _mercatorX(double lon) {
    return ((lon + 180) / 360) * _tileSize;
  }

  static double _mercatorY(double lat) {
    final clamped = _clampLat(lat);
    final radians = (clamped * pi) / 180;
    final y = log(tan(pi / 4 + radians / 2));
    return (_tileSize / 2) * (1 - y / pi);
  }

  static double _lonFromMercatorX(double x) {
    return _normalizeLon((x / _tileSize) * 360 - 180);
  }

  static double _latFromMercatorY(double y) {
    final n = pi - (2 * pi * y) / _tileSize;
    return (180 / pi) * atan(sinh(n));
  }

  static double sinh(double x) {
    return (exp(x) - exp(-x)) / 2;
  }

  static List<LatLng> _unwrapRoute(List<LatLng> points) {
    if (points.length <= 1) return points;
    final unwrapped = <LatLng>[LatLng(points[0].latitude, points[0].longitude)];
    double prevLon = points[0].longitude;

    for (int i = 1; i < points.length; i++) {
      final next = points[i];
      double lon = next.longitude;
      while (lon - prevLon > 180) {
        lon -= 360;
      }
      while (lon - prevLon < -180) {
        lon += 360;
      }
      unwrapped.add(LatLng(next.latitude, lon));
      prevLon = lon;
    }

    return unwrapped;
  }

  static StaticMapViewport buildViewport({
    required List<LatLng> points,
    double width = staticShareMapWidth,
    double height = staticShareMapHeight,
    EdgeInsets padding = const EdgeInsets.all(staticShareMapPadding),
  }) {
    if (points.isEmpty) {
      return StaticMapViewport(
        center: const LatLng(20, 0),
        zoom: 1.4,
        width: width,
        height: height,
      );
    }

    final sampled = _sampleRoutePoints(points);
    final unwrapped = _unwrapRoute(sampled);

    final xValues = unwrapped.map((p) => _mercatorX(p.longitude)).toList();
    final yValues = unwrapped.map((p) => _mercatorY(p.latitude)).toList();

    final minX = xValues.reduce(min);
    final maxX = xValues.reduce(max);
    final minY = yValues.reduce(min);
    final maxY = yValues.reduce(max);

    final spanX = max(1e-9, maxX - minX);
    final spanY = max(1e-9, maxY - minY);
    final availableW = max(1.0, width - padding.left - padding.right);
    final availableH = max(1.0, height - padding.top - padding.bottom);

    // log2 doesn't exist natively, use log(x)/log(2)
    final zoomX = log(availableW / spanX) / ln2;
    final zoomY = log(availableH / spanY) / ln2;
    final double zoom = min(max(0.5, min(zoomX, zoomY)), 7.8);

    final scale = pow(2, zoom);
    // Positive right/bottom padding should shift content left/up in screen space.
    // Convert padding deltas from pixels to mercator units via current zoom scale.
    final centerX =
        (minX + maxX) / 2 + (padding.right - padding.left) / (2 * scale);
    final centerY =
        (minY + maxY) / 2 + (padding.bottom - padding.top) / (2 * scale);

    return StaticMapViewport(
      center: LatLng(_latFromMercatorY(centerY), _lonFromMercatorX(centerX)),
      zoom: double.parse(zoom.toStringAsFixed(2)),
      width: width,
      height: height,
    );
  }

  /// Inverse of [projectRoute] for a single pixel of the viewport: which
  /// coordinate sits at [point]? Used to place the full-card weather grid.
  static LatLng unproject({
    required StaticMapViewport viewport,
    required Offset point,
  }) {
    final worldSize = _tileSize * pow(2, viewport.zoom);
    final centerX =
        (_normalizeLon(viewport.center.longitude) + 180) / 360 * worldSize;
    final centerY =
        _mercatorY(viewport.center.latitude) * pow(2, viewport.zoom);
    final pointX = centerX + (point.dx - viewport.width / 2);
    final pointY = centerY + (point.dy - viewport.height / 2);
    return LatLng(
      _latFromMercatorY(pointY / pow(2, viewport.zoom)),
      _normalizeLon(pointX / worldSize * 360 - 180),
    );
  }

  static List<ProjectedPoint> projectRoute({
    required List<LatLng> points,
    required StaticMapViewport viewport,
  }) {
    if (points.isEmpty) return [];

    final sampled = _sampleRoutePoints(points);
    final unwrapped = _unwrapRoute(sampled);

    final worldSize = _tileSize * pow(2, viewport.zoom);
    final centerX =
        (_normalizeLon(viewport.center.longitude) + 180) / 360 * worldSize;
    final centerY =
        _mercatorY(viewport.center.latitude) * pow(2, viewport.zoom);

    return unwrapped.map((point) {
      // Keep the unwrapped longitude for continuity across anti-meridian
      // routes. Re-normalizing here can reintroduce cross-world jumps.
      final pointX = (point.longitude + 180) / 360 * worldSize;
      final pointY = _mercatorY(point.latitude) * pow(2, viewport.zoom);

      double deltaX = pointX - centerX;
      while (deltaX > worldSize / 2) {
        deltaX -= worldSize;
      }
      while (deltaX < -worldSize / 2) {
        deltaX += worldSize;
      }

      return ProjectedPoint(
        x: viewport.width / 2 + deltaX,
        y: viewport.height / 2 + (pointY - centerY),
        lat: point.latitude,
        lon: point.longitude,
      );
    }).toList();
  }
}
