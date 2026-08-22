import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/policy/flight_overhead_time_policy.dart';

void main() {
  group('FlightOverheadTimePolicy', () {
    final departure = DateTime.utc(2026, 8, 3, 10);
    final arrival = DateTime.utc(2026, 8, 3, 12);

    test('keeps route progress out of the estimated taxi windows', () {
      expect(
        FlightOverheadTimePolicy.estimate(
          departureUtc: departure,
          arrivalUtc: arrival,
          cruiseMinutes: 90,
          routeProgress: 0,
        ),
        DateTime.utc(2026, 8, 3, 10, 15),
      );
      expect(
        FlightOverheadTimePolicy.estimate(
          departureUtc: departure,
          arrivalUtc: arrival,
          cruiseMinutes: 90,
          routeProgress: 1,
        ),
        DateTime.utc(2026, 8, 3, 11, 50),
      );
    });

    test('interpolates through the remaining airborne window', () {
      expect(
        FlightOverheadTimePolicy.estimate(
          departureUtc: departure,
          arrivalUtc: arrival,
          cruiseMinutes: 90,
          routeProgress: 0.5,
        ),
        DateTime.utc(2026, 8, 3, 11, 2, 30),
      );
    });

    test('falls back to block progress without a valid cruise estimate', () {
      expect(
        FlightOverheadTimePolicy.estimate(
          departureUtc: departure,
          arrivalUtc: arrival,
          cruiseMinutes: 0,
          routeProgress: 0.25,
        ),
        DateTime.utc(2026, 8, 3, 10, 30),
      );
    });
  });
}
