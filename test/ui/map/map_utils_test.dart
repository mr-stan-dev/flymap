import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:latlong2/latlong.dart';

void main() {
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
      expect(proLabel, '60-100 MB');
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
