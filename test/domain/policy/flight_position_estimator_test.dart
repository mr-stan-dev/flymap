import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_map_position.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/domain/policy/flight_position_estimator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('FlightPositionEstimator', () {
    test('projects a stable airborne trajectory without route geometry', () {
      final estimator = _estimator();
      final start = DateTime.utc(2026, 9, 2, 12);
      _recordEastboundCruise(estimator, start);

      final position = estimator.estimate(
        now: start.add(const Duration(seconds: 64)),
      );

      expect(position?.source, FlightMapPositionSource.estimated);
      expect(position?.confidence, FlightMapPositionConfidence.high);
      expect(position?.data.latitude, closeTo(50, 0.001));
      expect(position!.data.longitude!, greaterThan(5.0112));
      expect(position.data.course, closeTo(90, 1));
    });

    test('reduces confidence and stops advancing after ten minutes', () {
      final estimator = _estimator();
      final start = DateTime.utc(2026, 9, 2, 12);
      _recordEastboundCruise(estimator, start);

      final lowConfidence = estimator.estimate(
        now: start.add(const Duration(minutes: 3, seconds: 4)),
      );
      final atLimit = estimator.estimate(
        now: start.add(const Duration(minutes: 10, seconds: 4)),
      );
      final expired = estimator.estimate(
        now: start.add(const Duration(minutes: 15)),
      );

      expect(lowConfidence?.source, FlightMapPositionSource.estimated);
      expect(lowConfidence?.confidence, FlightMapPositionConfidence.low);
      expect(atLimit?.source, FlightMapPositionSource.estimated);
      expect(expired?.source, FlightMapPositionSource.lastKnown);
      expect(expired?.confidence, FlightMapPositionConfidence.none);
      expect(
        expired?.data.latitude,
        closeTo(atLimit!.data.latitude!, 0.000001),
      );
      expect(
        expired?.data.longitude,
        closeTo(atLimit.data.longitude!, 0.000001),
      );
    });

    test('does not advance a stationary runway fix', () {
      final estimator = FlightPositionEstimator(
        departure: const LatLng(50, 5),
        arrival: const LatLng(50, 15),
      );
      final start = DateTime.utc(2026, 9, 2, 12);
      for (var index = 0; index < 3; index++) {
        final at = start.add(Duration(seconds: index * 2));
        estimator.recordFix(
          _fix(latitude: 50, longitude: 5.001, speedKmh: 0, at: at),
          receivedAt: at,
        );
      }

      final position = estimator.estimate(
        now: start.add(const Duration(minutes: 2)),
      );

      expect(position?.source, FlightMapPositionSource.lastKnown);
      expect(position?.data.longitude, 5.001);
    });

    test('rejects inconsistent reported course and observed movement', () {
      final estimator = _estimator();
      final start = DateTime.utc(2026, 9, 2, 12);
      for (var index = 0; index < 3; index++) {
        final at = start.add(Duration(seconds: index * 2));
        estimator.recordFix(
          _fix(
            latitude: 50,
            longitude: 5 + index * 0.0056,
            speedKmh: 720,
            course: 0,
            at: at,
          ),
          receivedAt: at,
        );
      }

      final position = estimator.estimate(
        now: start.add(const Duration(minutes: 1)),
      );

      expect(position?.source, FlightMapPositionSource.lastKnown);
      expect(position?.data.longitude, closeTo(5.0112, 0.000001));
    });

    test('handles eastbound antimeridian extrapolation', () {
      final estimator = FlightPositionEstimator(
        departure: const LatLng(0, 160),
        arrival: const LatLng(0, -160),
      );
      final start = DateTime.utc(2026, 9, 2, 12);
      final longitudes = [179.98, 179.99, -180.0];
      for (var index = 0; index < longitudes.length; index++) {
        final at = start.add(Duration(seconds: index * 5));
        estimator.recordFix(
          _fix(
            latitude: 0,
            longitude: longitudes[index],
            speedKmh: 800,
            at: at,
          ),
          receivedAt: at,
        );
      }

      final position = estimator.estimate(
        now: start.add(const Duration(seconds: 70)),
      );

      expect(position?.source, FlightMapPositionSource.estimated);
      expect(position!.data.longitude!, greaterThan(-180));
      expect(position.data.longitude!, lessThan(-179.8));
    });
  });
}

FlightPositionEstimator _estimator() {
  return FlightPositionEstimator(
    departure: const LatLng(50, 0),
    arrival: const LatLng(50, 15),
  );
}

void _recordEastboundCruise(FlightPositionEstimator estimator, DateTime start) {
  for (var index = 0; index < 3; index++) {
    final at = start.add(Duration(seconds: index * 2));
    estimator.recordFix(
      _fix(latitude: 50, longitude: 5 + index * 0.0056, speedKmh: 720, at: at),
      receivedAt: at,
    );
  }
}

GpsData _fix({
  required double latitude,
  required double longitude,
  required double speedKmh,
  required DateTime at,
  double course = 90,
}) {
  return GpsData(
    latitude: latitude,
    longitude: longitude,
    altitude: const AltitudeValue(11000, 'm'),
    speed: SpeedValue(speedKmh, 'km/h'),
    course: course,
    accuracy: 12,
    speedAccuracy: 5,
    courseAccuracy: 5,
    recordedAt: at,
  );
}
