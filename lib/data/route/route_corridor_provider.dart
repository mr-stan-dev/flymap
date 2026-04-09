import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../../logger.dart';

/// Provider for calculating route corridors around create_flight paths
class RouteCorridorProvider {
  final _logger = Logger('RouteCorridorProvider');

  /// Calculate a corridor around a route with specified width
  ///
  /// [route] - List of coordinates representing the route
  /// [widthKm] - Width of the corridor in kilometers
  /// [bufferRadiusKm] - Buffer radius to extend route length at ends
  /// Returns a list of polygon coordinates representing the corridor
  List<LatLng> calculateCorridor(
    List<LatLng> route, {
    required double widthKm,
  }) {
    if (route.length < 2) return route;

    _logger.log('=== CORRIDOR GENERATION DEBUG ===');
    _logger.log('Route length: ${route.length}');
    _logger.log('Width: ${widthKm}km');
    _logger.log(
      'First route point: ${route.first.latitude}, ${route.first.longitude}',
    );
    _logger.log(
      'Last route point: ${route.last.latitude}, ${route.last.longitude}',
    );

    // Rounded caps already handle corridor ends, so we do not extend the route.
    final finalCorridor = _generateMainCorridor(route, widthKm);

    _logger.log('Final corridor points: ${finalCorridor.length}');

    if (finalCorridor.isNotEmpty) {
      _logger.log(
        'First corridor point: ${finalCorridor.first.latitude}, ${finalCorridor.first.longitude}',
      );
      _logger.log(
        'Last corridor point: ${finalCorridor.last.latitude}, ${finalCorridor.last.longitude}',
      );

      // Check for invalid coordinates
      bool hasInvalidCoords = false;
      for (int i = 0; i < finalCorridor.length; i++) {
        final point = finalCorridor[i];
        if (point.latitude.isNaN ||
            point.longitude.isNaN ||
            point.latitude.isInfinite ||
            point.longitude.isInfinite) {
          _logger.error(
            'Invalid coordinate at index $i: ${point.latitude}, ${point.longitude}',
          );
          hasInvalidCoords = true;
        }
      }
      if (hasInvalidCoords) {
        _logger.error('Corridor contains invalid coordinates!');
        return [];
      }
    }
    _logger.log('=== END CORRIDOR DEBUG ===');

    return finalCorridor;
  }

  /// Generate the main corridor along the route
  List<LatLng> _generateMainCorridor(List<LatLng> route, double widthKm) {
    List<LatLng> leftPoints = [];
    List<LatLng> rightPoints = [];

    for (int i = 0; i < route.length; i++) {
      final point = route[i];
      LatLng? offset;

      // Use the base width for all points
      double effectiveWidth = widthKm;

      if (i == 0) {
        // First point - use direction to next point
        offset = _calculatePerpendicularOffset(
          point,
          route[i + 1],
          effectiveWidth / 2,
        );
      } else if (i == route.length - 1) {
        // Last point - use direction from previous point
        offset = _calculatePerpendicularOffset(
          route[i - 1],
          point,
          effectiveWidth / 2,
        );
      } else {
        // Middle point - average the directions
        final offset1 = _calculatePerpendicularOffset(
          route[i - 1],
          point,
          effectiveWidth / 2,
        );
        final offset2 = _calculatePerpendicularOffset(
          point,
          route[i + 1],
          effectiveWidth / 2,
        );
        offset = LatLng(
          (offset1.latitude + offset2.latitude) / 2,
          (offset1.longitude + offset2.longitude) / 2,
        );
      }

      final leftPoint = LatLng(
        point.latitude + offset.latitude,
        point.longitude + offset.longitude,
      );

      final rightPoint = LatLng(
        point.latitude - offset.latitude,
        point.longitude - offset.longitude,
      );

      leftPoints.add(leftPoint);
      rightPoints.add(rightPoint);
    }

    // Build corridor with rounded caps to avoid square ends near departure/arrival.
    final capRadiusKm = widthKm / 2;
    final startForwardBearing = _calculateBearing(route[0], route[1]);
    final endForwardBearing = _calculateBearing(
      route[route.length - 2],
      route[route.length - 1],
    );
    final startCap = _buildRoundedCap(
      center: route.first,
      fromPoint: rightPoints.first,
      toPoint: leftPoints.first,
      radiusKm: capRadiusKm,
      preferredMidBearing: _normalizeBearing(startForwardBearing + 180),
    );
    final endCap = _buildRoundedCap(
      center: route.last,
      fromPoint: leftPoints.last,
      toPoint: rightPoints.last,
      radiusKm: capRadiusKm,
      preferredMidBearing: endForwardBearing,
    );

    List<LatLng> corridor = [];
    corridor.addAll(startCap);
    if (leftPoints.length > 2) {
      corridor.addAll(leftPoints.sublist(1, leftPoints.length - 1));
    }
    corridor.addAll(endCap);
    if (rightPoints.length > 2) {
      corridor.addAll(rightPoints.sublist(1, rightPoints.length - 1).reversed);
    }

    // Close the polygon by adding the first point at the end.
    if (corridor.isNotEmpty &&
        (corridor.first.latitude != corridor.last.latitude ||
            corridor.first.longitude != corridor.last.longitude)) {
      corridor.add(corridor.first);
    }

    return corridor;
  }

  /// Calculate a point at a given distance and bearing from a starting point
  ///
  /// [start] - Starting point
  /// [distanceKm] - Distance in kilometers
  /// [bearingDegrees] - Bearing in degrees
  /// Returns the calculated point
  LatLng _calculatePointAtDistance(
    LatLng start,
    double distanceKm,
    double bearingDegrees,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert to radians
    final lat1 = start.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final bearingRad = bearingDegrees * pi / 180;

    // Calculate angular distance
    final angularDistance = distanceKm / earthRadius;

    // Calculate destination point
    final lat2 = asin(
      sin(lat1) * cos(angularDistance) +
          cos(lat1) * sin(angularDistance) * cos(bearingRad),
    );

    final lon2 =
        lon1 +
        atan2(
          sin(bearingRad) * sin(angularDistance) * cos(lat1),
          cos(angularDistance) - sin(lat1) * sin(lat2),
        );

    // Convert back to degrees
    return LatLng(lat2 * 180 / pi, lon2 * 180 / pi);
  }

  /// Calculate perpendicular offset for corridor generation
  ///
  /// [start] - Starting point
  /// [end] - Ending point
  /// [distanceKm] - Distance to offset in kilometers
  /// Returns the offset coordinates
  LatLng _calculatePerpendicularOffset(
    LatLng start,
    LatLng end,
    double distanceKm,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Calculate bearing
    final bearing = _calculateBearing(start, end);

    // Calculate perpendicular bearing (90 degrees to the right)
    final perpendicularBearing = bearing + 90;

    // Convert to radians
    final lat1 = start.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final bearingRad = perpendicularBearing * pi / 180;

    // Calculate offset point
    final angularDistance = distanceKm / earthRadius;

    final lat2 = asin(
      sin(lat1) * cos(angularDistance) +
          cos(lat1) * sin(angularDistance) * cos(bearingRad),
    );

    final lon2 =
        lon1 +
        atan2(
          sin(bearingRad) * sin(angularDistance) * cos(lat1),
          cos(angularDistance) - sin(lat1) * sin(lat2),
        );

    // Convert back to degrees and calculate offset
    final offsetLat = lat2 * 180 / pi - start.latitude;
    final offsetLon = lon2 * 180 / pi - start.longitude;

    final offset = LatLng(offsetLat, offsetLon);

    return offset;
  }

  /// Build a smooth arc cap between two corridor edge points around [center].
  ///
  /// Chooses the arc whose midpoint is closest to [preferredMidBearing].
  List<LatLng> _buildRoundedCap({
    required LatLng center,
    required LatLng fromPoint,
    required LatLng toPoint,
    required double radiusKm,
    required double preferredMidBearing,
    int segments = 16,
  }) {
    final startBearing = _calculateBearing(center, fromPoint);
    final endBearing = _calculateBearing(center, toPoint);

    final clockwiseDelta = _normalizeBearing(endBearing - startBearing);
    final counterClockwiseDelta = clockwiseDelta == 0
        ? -360.0
        : clockwiseDelta - 360.0;

    final clockwiseMid = _normalizeBearing(startBearing + clockwiseDelta / 2);
    final counterClockwiseMid = _normalizeBearing(
      startBearing + counterClockwiseDelta / 2,
    );

    final clockwiseDistance = _bearingDistance(
      clockwiseMid,
      preferredMidBearing,
    );
    final counterClockwiseDistance = _bearingDistance(
      counterClockwiseMid,
      preferredMidBearing,
    );

    final selectedDelta = clockwiseDistance <= counterClockwiseDistance
        ? clockwiseDelta
        : counterClockwiseDelta;

    final stepCount = segments < 1 ? 1 : segments;
    final arc = <LatLng>[];
    for (int i = 0; i <= stepCount; i++) {
      final t = i / stepCount;
      final bearing = _normalizeBearing(startBearing + selectedDelta * t);
      arc.add(_calculatePointAtDistance(center, radiusKm, bearing));
    }
    return arc;
  }

  double _normalizeBearing(double bearing) {
    final normalized = bearing % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _bearingDistance(double a, double b) {
    final diff = (_normalizeBearing(a - b)).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  /// Calculate bearing between two points
  ///
  /// [start] - Starting point
  /// [end] - Ending point
  /// Returns the bearing in degrees
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final dLon = (end.longitude - start.longitude) * pi / 180;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360; // Normalize to 0-360
  }

  /// Calculate the area of a corridor in square kilometers
  ///
  /// [route] - Route coordinates
  /// [widthKm] - Width of the corridor
  /// [bufferRadiusKm] - Radius of buffer zones
  /// Returns the area in square kilometers
  double calculateCorridorArea(
    List<LatLng> route,
    double widthKm, {
    double bufferRadiusKm = 50.0,
  }) {
    if (route.length < 2) return 0;

    // Calculate main corridor area
    double totalDistance = 0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistance(route[i], route[i + 1]);
    }
    double mainArea = totalDistance * widthKm;

    // Calculate buffer areas
    double departureBufferArea = pi * bufferRadiusKm * bufferRadiusKm;
    double arrivalBufferArea = pi * bufferRadiusKm * bufferRadiusKm;

    return mainArea + departureBufferArea + arrivalBufferArea;
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371;

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
