import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/map_detail_level.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('MapUtils.interpolateGreatCircle', () {
    test('a transatlantic midpoint arcs north of a coordinate lerp', () {
      final midpoint = MapUtils.interpolateGreatCircle(
        from: const LatLng(51.4700, -0.4543),
        to: const LatLng(40.6413, -73.7781),
        progress: 0.5,
      );

      expect(midpoint.latitude, greaterThan(52));
      expect(midpoint.longitude, closeTo(-41.3, 1));
    });

    test('crosses the antimeridian by the short path', () {
      final midpoint = MapUtils.interpolateGreatCircle(
        from: const LatLng(10, 170),
        to: const LatLng(10, -170),
        progress: 0.5,
      );

      expect(midpoint.latitude, greaterThan(10));
      expect(midpoint.longitude.abs(), closeTo(180, 0.001));
    });
  });

  group('MapUtils.estimatedDownloadSizeRangeLabel', () {
    test('uses fallback baseline when route is null', () {
      final label = MapUtils.estimatedDownloadSizeRangeLabel(
        route: null,
        mapDetailLevel: MapDetailLevel.basic,
        selectedArticlesCount: 0,
      );
      expect(label, '30-50 MB');
    });

    test('adds article overhead and rounds up to 10MB', () {
      final label = MapUtils.estimatedDownloadSizeRangeLabel(
        route: null,
        mapDetailLevel: MapDetailLevel.basic,
        selectedArticlesCount: 3,
      );
      expect(label, '40-60 MB');
    });

    test('applies Europe multiplier', () {
      final route = FlightRoute(
        departure: _airport('CDG', 49.0097, 2.5479),
        arrival: _airport('FRA', 50.0379, 8.5622),
        waypoints: const [],
        corridor: const [],
        metrics: FlightRouteMetrics.fromLegacyDistance(450),
      );

      final label = MapUtils.estimatedDownloadSizeRangeLabel(
        route: route,
        mapDetailLevel: MapDetailLevel.basic,
        selectedArticlesCount: 0,
      );
      expect(label, '30-50 MB');
    });

    test('pro detail level increases estimate for short routes', () {
      final route = FlightRoute(
        departure: _airport('CDG', 49.0097, 2.5479),
        arrival: _airport('FRA', 50.0379, 8.5622),
        waypoints: const [],
        corridor: const [],
        metrics: FlightRouteMetrics.fromLegacyDistance(450),
      );

      final basicLabel = MapUtils.estimatedDownloadSizeRangeLabel(
        route: route,
        mapDetailLevel: MapDetailLevel.basic,
        selectedArticlesCount: 0,
      );
      final proLabel = MapUtils.estimatedDownloadSizeRangeLabel(
        route: route,
        mapDetailLevel: MapDetailLevel.pro,
        selectedArticlesCount: 0,
      );

      expect(basicLabel, '30-50 MB');
      expect(proLabel, '50-90 MB');
    });
  });
}

Airport _airport(String code, double lat, double lon) {
  return Airport(
    name: code,
    city: code,
    countryCode: 'XX',
    latLon: LatLng(lat, lon),
    iataCode: code,
    icaoCode: code,
    wikipediaUrl: '',
  );
}
