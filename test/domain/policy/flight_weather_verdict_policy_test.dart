import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:latlong2/latlong.dart';

FlightSchedule _legacyDateOnly(DateTime date) =>
    FlightSchedule(travelDate: DateTime(date.year, date.month, date.day));

RouteCloudSample _sample({
  required double progress,
  double low = 0,
  double mid = 0,
  double high = 0,
}) {
  return RouteCloudSample(
    routeProgress: progress,
    latLon: const LatLng(50, 10),
    timeUtc: DateTime.utc(2026, 8, 3, 10),
    cloudLowPercent: low,
    cloudMidPercent: mid,
    cloudHighPercent: high,
  );
}

void main() {
  group('FlightWeatherVerdictPolicy', () {
    test('overall verdict averages across the route', () {
      final samples = [
        _sample(progress: 0.2, low: 0),
        _sample(progress: 0.5, low: 90),
        _sample(progress: 0.8, low: 0),
      ];
      // Mean hidden = 30 -> patchy.
      expect(
        FlightWeatherVerdictPolicy.overallVerdict(samples),
        WindowVerdict.patchyClouds,
      );
    });
  });

  group('isBeyondForecastHorizon', () {
    final now = DateTime.utc(2026, 7, 30, 12);

    bool beyond(FlightSchedule? schedule) =>
        FlightWeatherVerdictPolicy.isBeyondForecastHorizon(schedule, now: now);

    test('no schedule (dateless flight) is never too far', () {
      expect(beyond(null), isFalse);
    });

    test('scheduled departure inside the horizon fetches', () {
      expect(
        beyond(
          FlightSchedule(
            travelDate: DateTime(2026, 8, 2),
            departure: ZonedInstant(
              utc: DateTime.utc(2026, 8, 2, 15),
              offsetMinutes: 60,
            ),
          ),
        ),
        isFalse,
      );
    });

    test('scheduled departure two months out is beyond', () {
      expect(
        beyond(
          FlightSchedule(
            travelDate: DateTime(2026, 9, 30),
            departure: ZonedInstant(
              utc: DateTime.utc(2026, 9, 30, 15),
              offsetMinutes: 60,
            ),
          ),
        ),
        isTrue,
      );
    });

    test('date-only schedule compares calendar days', () {
      expect(beyond(_legacyDateOnly(DateTime(2026, 8, 6))), isFalse);
      expect(beyond(_legacyDateOnly(DateTime(2026, 10, 1))), isTrue);
    });

    test('the seventh day itself is still inside the horizon', () {
      expect(beyond(_legacyDateOnly(DateTime(2026, 8, 6))), isFalse);
      expect(beyond(_legacyDateOnly(DateTime(2026, 8, 7))), isTrue);
    });
  });

  group('isInPast', () {
    final now = DateTime(2026, 8, 4, 21);

    test('rejects an earlier calendar date', () {
      expect(
        FlightWeatherVerdictPolicy.isInPast(
          _legacyDateOnly(DateTime(2026, 8, 3)),
          now: now,
        ),
        isTrue,
      );
    });

    test('keeps Today eligible even after the default noon estimate', () {
      expect(
        FlightWeatherVerdictPolicy.isInPast(
          _legacyDateOnly(DateTime(2026, 8, 4)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
