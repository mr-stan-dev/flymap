import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';

void main() {
  group('FlightRouteMetrics display rounding', () {
    test('rounds actual distance for display', () {
      const metrics = FlightRouteMetrics(
        greatCircleDistanceKm: 10980,
        cruiseMinutes: 810,
        actualDistanceKm: 11121,
        actualBlockMinutes: 823,
      );

      expect(metrics.displayDistanceKm, 11120);
    });

    test('keeps estimated distance unrounded beyond integer km', () {
      const metrics = FlightRouteMetrics(
        greatCircleDistanceKm: 347.4,
        cruiseMinutes: 54,
      );

      expect(metrics.displayDistanceKm, 347);
    });
  });

  group('FlightRouteMetrics.cruiseSpeedKmh', () {
    test('derives true cruise speed from cruise minutes', () {
      const metrics = FlightRouteMetrics(
        greatCircleDistanceKm: 1850,
        cruiseMinutes: 130,
      );

      expect(metrics.cruiseSpeedKmh, closeTo(853.8, 0.1));
    });

    test('ignores actual block time so the speed is never a block average', () {
      const metrics = FlightRouteMetrics(
        greatCircleDistanceKm: 1850,
        cruiseMinutes: 130,
        actualDistanceKm: 1900,
        actualBlockMinutes: 185,
      );

      expect(metrics.cruiseSpeedKmh, closeTo(853.8, 0.1));
    });

    test('is null without cruise data', () {
      const metrics = FlightRouteMetrics(
        greatCircleDistanceKm: 0,
        cruiseMinutes: 0,
      );

      expect(metrics.cruiseSpeedKmh, isNull);
    });
  });
}
