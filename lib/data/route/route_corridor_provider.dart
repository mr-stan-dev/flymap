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

    // Extend the route at both ends if buffer radius is specified
    final bufferRadiusKm = widthKm / 2;
    List<LatLng> extendedRoute = _extendRouteAtEnds(route, bufferRadiusKm);

    // Generate main corridor using the extended route
    final finalCorridor = _generateMainCorridor(extendedRoute, widthKm);

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

    // Create polygon: left points + right points in reverse order
    List<LatLng> corridor = [];
    corridor.addAll(leftPoints);
    corridor.addAll(rightPoints.reversed);

    // Smoothly close the polygon to avoid sharp corners
    // Close the polygon by adding the first point at the end
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

  /// Extend the route at both ends by the specified distance
  List<LatLng> _extendRouteAtEnds(List<LatLng> route, double extensionKm) {
    if (route.length < 2) return route;

    List<LatLng> extendedRoute = [];

    // Extend at the departure end (first point)
    final departureBearing = _calculateBearing(route[0], route[1]);
    final departureExtension = _calculatePointAtDistance(
      route[0],
      extensionKm,
      departureBearing + 180, // Opposite direction
    );
    extendedRoute.add(departureExtension);

    // Add all original route points
    extendedRoute.addAll(route);

    // Extend at the arrival end (last point)
    final arrivalBearing = _calculateBearing(
      route[route.length - 2],
      route[route.length - 1],
    );
    final arrivalExtension = _calculatePointAtDistance(
      route[route.length - 1],
      extensionKm,
      arrivalBearing, // Same direction
    );
    extendedRoute.add(arrivalExtension);

    return extendedRoute;
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
