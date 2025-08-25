import 'dart:math';

import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/data/route/route_corridor_provider.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:latlong2/latlong.dart';

/// Provider for calculating great circle routes between two points
class GreatCircleRouteProvider implements FlightRouteProvider {
  final corridorProvider = RouteCorridorProvider();
  static const _wayPointDensityKm = 100;
  static const _corridorWidthKm = 100.0;

  @override
  FlightRoute getRoute({required Airport departure, required Airport arrival}) {
    final waypoints = calculateRoute(departure.latLon, arrival.latLon);
    final corridor = corridorProvider.calculateCorridor(
      waypoints,
      widthKm: _corridorWidthKm,
    );
    return FlightRoute(
      departure: departure,
      arrival: arrival,
      waypoints: waypoints,
      corridor: corridor,
    );
  }

  List<LatLng> calculateRoute(LatLng start, LatLng end) {
    List<LatLng> route = [];

    final distanceKm = MapUtils.distanceKm(departure: start, arrival: end);

    final segments = (distanceKm / _wayPointDensityKm).round();

    for (int i = 0; i <= segments; i++) {
      final fraction = i / segments;
      final point = _interpolatePoint(start, end, fraction);
      route.add(point);
    }

    return route;
  }

  /// Calculate multiple route segments for antimeridian crossing
  /// This method returns multiple route segments that can be rendered as separate polylines
  ///
  /// [start] - Starting point coordinates
  /// [end] - Ending point coordinates
  /// [segments] - Number of segments to divide the route into
  /// Returns a list of route segments, each segment is a list of coordinates
  List<List<LatLng>> calculateRouteSegments(
    LatLng start,
    LatLng end, {
    int segments = 10,
  }) {
    // Fix antimeridian wrapping before calculating the route
    final normalizedPoints = _fixAntimeridianWrap(start, end);
    final normalizedStart = normalizedPoints[0];
    final normalizedEnd = normalizedPoints[1];

    // Check if the normalized route crosses the antimeridian
    if (_crossesAntimeridian(normalizedStart, normalizedEnd)) {
      return _calculateRouteSegmentsWithAntimeridianCrossing(
        normalizedStart,
        normalizedEnd,
        segments,
      );
    } else {
      return [_calculateSimpleRoute(normalizedStart, normalizedEnd, segments)];
    }
  }

  /// Fix antimeridian wrapping by adjusting longitudes to cross the short way
  List<LatLng> _fixAntimeridianWrap(LatLng start, LatLng end) {
    if ((start.longitude - end.longitude).abs() > 180) {
      // Adjust longitudes so they cross the antimeridian the short way
      if (start.longitude > end.longitude) {
        end = LatLng(end.latitude, end.longitude + 360);
      } else {
        start = LatLng(start.latitude, start.longitude + 360);
      }
    }
    return [start, end];
  }

  /// Check if a route crosses the antimeridian
  bool _crossesAntimeridian(LatLng start, LatLng end) {
    final startLon = _normalizeLongitude(start.longitude);
    final endLon = _normalizeLongitude(end.longitude);
    return (endLon - startLon).abs() > 180;
  }

  /// Calculate route segments that cross the antimeridian
  List<List<LatLng>> _calculateRouteSegmentsWithAntimeridianCrossing(
    LatLng start,
    LatLng end,
    int segments,
  ) {
    // Calculate the full route first
    final fullRoute = _calculateSimpleRoute(start, end, segments);

    // Find where the route crosses the antimeridian
    final crossingIndex = _findAntimeridianCrossingIndex(fullRoute);

    if (crossingIndex == -1) {
      // No crossing found, return single segment
      return [fullRoute];
    }

    // Split the route at the crossing point
    final firstSegment = fullRoute.sublist(0, crossingIndex + 1);
    final secondSegment = fullRoute.sublist(crossingIndex);

    // Clean the segments to ensure they stop at the antimeridian
    final cleanFirstSegment = _cleanSegmentToAntimeridian(firstSegment, true);
    final cleanSecondSegment = _cleanSegmentToAntimeridian(
      secondSegment,
      false,
    );

    return [cleanFirstSegment, cleanSecondSegment];
  }

  /// Find the index where the route crosses the antimeridian
  int _findAntimeridianCrossingIndex(List<LatLng> route) {
    for (int i = 1; i < route.length; i++) {
      final prevLon = route[i - 1].longitude;
      final currLon = route[i].longitude;

      // Check if we've crossed the antimeridian
      if ((prevLon > 0 && currLon < 0) || (prevLon < 0 && currLon > 0)) {
        return i - 1; // Return the index before the crossing
      }
    }
    return -1; // No crossing found
  }

  /// Clean a route segment to stop exactly at the antimeridian
  List<LatLng> _cleanSegmentToAntimeridian(
    List<LatLng> segment,
    bool isFirstSegment,
  ) {
    if (segment.isEmpty) return segment;

    final cleanedSegment = <LatLng>[];

    for (int i = 0; i < segment.length; i++) {
      final point = segment[i];

      if (isFirstSegment) {
        // For the first segment, include points until we reach the antimeridian
        if (point.longitude >= 180) {
          // We've reached the antimeridian, add the point at exactly 180° and stop
          cleanedSegment.add(LatLng(point.latitude, 180.0));
          break;
        } else if (point.longitude <= -180) {
          // We've reached the antimeridian, add the point at exactly -180° and stop
          cleanedSegment.add(LatLng(point.latitude, -180.0));
          break;
        }
        cleanedSegment.add(point);
      } else {
        // For the second segment, start from the antimeridian
        if (i == 0) {
          // First point should be at the antimeridian
          if (point.longitude > 0) {
            cleanedSegment.add(LatLng(point.latitude, 180.0));
          } else {
            cleanedSegment.add(LatLng(point.latitude, -180.0));
          }
        } else {
          // Include the rest of the points
          cleanedSegment.add(point);
        }
      }
    }

    return cleanedSegment;
  }

  /// Calculate a simple route without antimeridian crossing
  List<LatLng> _calculateSimpleRoute(LatLng start, LatLng end, int segments) {
    List<LatLng> route = [];

    for (int i = 0; i <= segments; i++) {
      final fraction = i / segments;
      final point = _interpolatePoint(start, end, fraction);
      route.add(point);
    }

    return route;
  }

  /// Interpolate a point along the great circle route
  ///
  /// [start] - Starting point
  /// [end] - Ending point
  /// [fraction] - Fraction along the route (0.0 to 1.0)
  /// Returns the interpolated point
  LatLng _interpolatePoint(LatLng start, LatLng end, double fraction) {
    // Convert to radians
    final lat1 = start.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final lon2 = end.longitude * pi / 180;

    // Calculate great circle distance
    final d =
        2 *
        asin(
          sqrt(
            pow(sin((lat2 - lat1) / 2), 2) +
                cos(lat1) * cos(lat2) * pow(sin((lon2 - lon1) / 2), 2),
          ),
        );

    if (d == 0) return start;

    // Calculate intermediate point
    final A = sin((1 - fraction) * d) / sin(d);
    final B = sin(fraction * d) / sin(d);

    final x = A * cos(lat1) * cos(lon1) + B * cos(lat2) * cos(lon2);
    final y = A * cos(lat1) * sin(lon1) + B * cos(lat2) * sin(lon2);
    final z = A * sin(lat1) + B * sin(lat2);

    final lat = atan2(z, sqrt(x * x + y * y));
    final lon = atan2(y, x);

    // Convert back to degrees
    return LatLng(lat * 180 / pi, lon * 180 / pi);
  }

  /// Normalize longitude to be within [-180, 180] range
  double _normalizeLongitude(double longitude) {
    double normalized = longitude;

    // Ensure the longitude is within [-180, 180] range
    while (normalized > 180) {
      normalized -= 360;
    }
    while (normalized < -180) {
      normalized += 360;
    }

    return normalized;
  }

  /// Calculate the distance between two points in kilometers
  ///
  /// [start] - Starting point
  /// [end] - Ending point
  /// Returns the distance in kilometers
  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final lat1 = start.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final lon2 = end.longitude * pi / 180;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
