import 'dart:math';

import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/map_download_config.dart';
import 'package:latlong2/latlong.dart';

class MapUtils {
  static String estimatedDownloadSizeRangeLabel({
    required FlightRoute? route,
    required MapDetailLevel mapDetailLevel,
    required int selectedArticlesCount,
  }) {
    final distanceKm =
        (route?.distanceInKm ?? MapDownloadConfig.fallbackDistanceKm).clamp(
          1.0,
          double.infinity,
        );
    final center = route == null ? null : routeCenter(route);
    final regionMultiplier = _regionMultiplier(center);
    final maxZoom = MapDownloadConfig.resolveMaxZoom(
      distanceKm: distanceKm,
      detailLevel: mapDetailLevel,
    );
    final zoomScale = MapDownloadConfig.zoomScaleForEstimate(maxZoom);

    final mapMinMb =
        (distanceKm / 1000.0) *
        MapDownloadConfig.estimatedMinMbPer1000Km *
        regionMultiplier *
        zoomScale;
    final mapMaxMb =
        (distanceKm / 1000.0) *
        MapDownloadConfig.estimatedMaxMbPer1000Km *
        regionMultiplier *
        zoomScale;
    final articlesMb =
        selectedArticlesCount * MapDownloadConfig.estimatedArticleMb;

    final minMb = _roundUpToNext10Mb(mapMinMb + articlesMb);
    final maxMb = _roundUpToNext10Mb(mapMaxMb + articlesMb);
    return '${minMb.toStringAsFixed(0)}-${maxMb.toStringAsFixed(0)} MB';
  }

  static double _roundUpToNext10Mb(double valueMb) {
    return (valueMb / 10.0).ceil() * 10.0;
  }

  static double _regionMultiplier(LatLng? center) {
    if (center == null) return 1.0;

    final lat = center.latitude;
    final lon = center.longitude;

    // Europe: typically denser vector tiles
    if (lat >= 35 && lat <= 72 && lon >= -12 && lon <= 45) return 1.8;

    // East Asia (Japan/Korea/coastal China)
    if (lat >= 20 && lat <= 50 && lon >= 100 && lon <= 145) return 1.4;

    // South Asia
    if (lat >= 5 && lat <= 35 && lon >= 65 && lon <= 95) return 1.2;

    // North America: usually lighter than Europe for this tileset
    if (lat >= 15 && lat <= 75 && lon >= -170 && lon <= -50) return 0.9;

    // South America
    if (lat >= -55 && lat <= 15 && lon >= -85 && lon <= -35) return 0.9;

    // Africa
    if (lat >= -35 && lat <= 37 && lon >= -20 && lon <= 52) return 0.9;

    // Australia / NZ region
    if (lat >= -50 && lat <= -10 && lon >= 110 && lon <= 180) return 0.9;

    return 1.0;
  }

  /// Calculate appropriate zoom level based on distance in degrees
  static double calculateZoomLevel({
    required Airport departure,
    required Airport arrival,
  }) {
    // Calculate bounds to include both airports
    double minLat = min(departure.latLon.latitude, arrival.latLon.latitude);
    double maxLat = max(departure.latLon.latitude, arrival.latLon.latitude);
    double minLng = min(departure.latLon.longitude, arrival.latLon.longitude);
    double maxLng = max(departure.latLon.longitude, arrival.latLon.longitude);

    // Add padding to bounds (20% on each side for airports)
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    // Calculate appropriate zoom level
    final latDiff = (maxLat - minLat).abs();
    final lngDiff = (maxLng - minLng).abs();
    final maxDiff = max(latDiff, lngDiff);
    // Better zoom calculation based on distance
    if (maxDiff > 50.0) {
      return 1.0; // Very long distance (intercontinental)
    } else if (maxDiff > 30.0) {
      return 2.0; // Long distance (continental)
    } else if (maxDiff > 20.0) {
      return 3.0; // Long distance (continental)
    } else if (maxDiff > 10.0) {
      return 4.0; // Medium-long distance
    } else if (maxDiff > 5.0) {
      return 5.0; // Medium distance
    } else if (maxDiff > 2.0) {
      return 6.0; // Medium-short distance
    } else if (maxDiff > 1.0) {
      return 7.0; // Short distance
    } else if (maxDiff > 0.5) {
      return 8.0; // Very short distance
    } else if (maxDiff > 0.1) {
      return 9.0; // Local distance
    } else if (maxDiff > 0.05) {
      return 10.0; // Very local
    } else if (maxDiff > 0.01) {
      return 11.0; // City level
    } else if (maxDiff > 0.005) {
      return 12.0; // District level
    } else if (maxDiff > 0.001) {
      return 13.0; // Street level
    } else {
      return 14.0; // Building level
    }
  }

  static LatLng routeCenter(FlightRoute route) {
    final lat =
        (route.departure.latLon.latitude + route.arrival.latLon.latitude) / 2;

    // Handle longitude wrapping for antimeridian crossing
    final lon = _calculateCenterLongitude(
      route.departure.latLon.longitude,
      route.arrival.latLon.longitude,
    );

    return LatLng(lat, lon);
  }

  /// Calculate center point between two airports, handling antimeridian crossing
  static LatLng center({required Airport departure, required Airport arrival}) {
    final lat = (departure.latLon.latitude + arrival.latLon.latitude) / 2;

    // Handle longitude wrapping for antimeridian crossing
    final lon = _calculateCenterLongitude(
      departure.latLon.longitude,
      arrival.latLon.longitude,
    );

    return LatLng(lat, lon);
  }

  /// Calculate center longitude, handling antimeridian crossing
  static double _calculateCenterLongitude(double lon1, double lon2) {
    // Normalize longitudes to handle antimeridian crossing
    double normalizedLon1 = _normalizeLongitude(lon1);
    double normalizedLon2 = _normalizeLongitude(lon2);

    // Calculate the shortest angular distance between the longitudes
    double deltaLon = normalizedLon2 - normalizedLon1;

    // Handle antimeridian crossing
    if (deltaLon > 180) {
      deltaLon -= 360;
    } else if (deltaLon < -180) {
      deltaLon += 360;
    }

    // Calculate the center longitude
    double centerLon = normalizedLon1 + deltaLon / 2;

    // Normalize the result back to [-180, 180] range
    return _normalizeLongitude(centerLon);
  }

  /// Normalize longitude to be within [-180, 180] range
  static double _normalizeLongitude(double longitude) {
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

  static String distanceFormatted({
    required Airport departure,
    required Airport arrival,
  }) {
    final distanceKm = distance(departure: departure, arrival: arrival);
    final roundedDistance = (distanceKm / 10).round() * 10;
    return '${roundedDistance}km';
  }

  static double distanceKm({
    required LatLng departure,
    required LatLng arrival,
  }) {
    final lat1 = departure.latitude;
    final lon1 = departure.longitude;
    final lat2 = arrival.latitude;
    final lon2 = arrival.longitude;

    const double earthRadiusKm = 6371.0; // Earth's radius in kilometers

    // Convert degrees to radians
    final lat1Rad = lat1 * pi / 180;
    final lon1Rad = lon1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final lon2Rad = lon2 * pi / 180;

    // Calculate differences
    final deltaLat = lat2Rad - lat1Rad;
    final deltaLon = lon2Rad - lon1Rad;

    // Haversine formula
    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Calculate distance
    return earthRadiusKm * c;
  }

  /// Calculate great circle distance in Km between two points on Earth's surface
  static double distance({
    required Airport departure,
    required Airport arrival,
  }) {
    return distanceKm(departure: departure.latLon, arrival: arrival.latLon);
  }

  /// Check if a point is inside a polygon using ray casting algorithm
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }
}
