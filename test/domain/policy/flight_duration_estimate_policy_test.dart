import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/policy/flight_duration_estimate_policy.dart';

void main() {
  group('FlightDurationEstimatePolicy', () {
    test('estimateCruiseMinutes returns cruise-only duration', () {
      final minutes = FlightDurationEstimatePolicy.estimateCruiseMinutes(
        distanceKm: 920,
        cruiseSpeedKmh: 850,
        roundToMinutes: 5,
      );

      expect(minutes, 65);
    });

    test('estimateBlockMinutes includes non-cruise overhead', () {
      final minutes = FlightDurationEstimatePolicy.estimateBlockMinutes(
        distanceKm: 920,
        cruiseSpeedKmh: 850,
        roundToMinutes: 5,
      );

      expect(minutes, 110);
    });

    test('normalizeBlockMinutes floors low API values by estimate', () {
      final minutes = FlightDurationEstimatePolicy.normalizeBlockMinutes(
        apiBlockMinutes: 65,
        distanceKm: 920,
        cruiseSpeedKmh: 850,
        roundToMinutes: 5,
      );

      expect(minutes, 110);
    });

    test('normalizeBlockMinutes keeps higher API values', () {
      final minutes = FlightDurationEstimatePolicy.normalizeBlockMinutes(
        apiBlockMinutes: 140,
        distanceKm: 920,
        cruiseSpeedKmh: 850,
        roundToMinutes: 5,
      );

      expect(minutes, 140);
    });

    test('estimateBlockMinutes for long-haul reaches around 8h', () {
      final minutes = FlightDurationEstimatePolicy.estimateBlockMinutes(
        distanceKm: 5540,
        cruiseSpeedKmh: 850,
        roundToMinutes: 5,
      );

      expect(minutes, 480);
    });
  });
}
