import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:latlong2/latlong.dart';

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
    test('classifies single samples by hidden-ground share', () {
      expect(
        FlightWeatherVerdictPolicy.sampleVerdict(_sample(progress: 0, low: 10)),
        WindowVerdict.clearViews,
      );
      expect(
        FlightWeatherVerdictPolicy.sampleVerdict(
          _sample(progress: 0, low: 20, mid: 20),
        ),
        WindowVerdict.patchyClouds,
      );
      expect(
        FlightWeatherVerdictPolicy.sampleVerdict(
          _sample(progress: 0, low: 70, high: 10),
        ),
        WindowVerdict.cloudCarpet,
      );
      expect(
        FlightWeatherVerdictPolicy.sampleVerdict(
          _sample(progress: 0, low: 70, high: 80),
        ),
        WindowVerdict.overcast,
      );
    });

    test('high cirrus alone stays clear — cruise sits inside/above it', () {
      expect(
        FlightWeatherVerdictPolicy.sampleVerdict(
          _sample(progress: 0, high: 90),
        ),
        WindowVerdict.clearViews,
      );
    });

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

    test('segments merge consecutive same-verdict samples', () {
      final samples = [
        for (var i = 0; i < 5; i++) _sample(progress: 0.1 + i * 0.1, low: 5),
        for (var i = 5; i < 10; i++) _sample(progress: 0.1 + i * 0.1, low: 90),
      ];
      final segments = FlightWeatherVerdictPolicy.segments(samples);
      expect(segments, hasLength(2));
      expect(segments.first.verdict, WindowVerdict.clearViews);
      expect(segments.last.verdict, WindowVerdict.cloudCarpet);
      expect(segments.first.startProgress, 0);
      expect(segments.last.endProgress, 1);
      // Boundary falls midway between sample 4 (0.5) and sample 5 (0.6).
      expect(segments.first.endProgress, closeTo(0.55, 1e-9));
    });

    test('a single-sample blip merges into its neighbour', () {
      final samples = [
        for (var i = 0; i < 4; i++) _sample(progress: 0.1 + i * 0.1, low: 5),
        _sample(progress: 0.5, low: 90),
        for (var i = 5; i < 9; i++) _sample(progress: 0.1 + i * 0.1, low: 5),
      ];
      final segments = FlightWeatherVerdictPolicy.segments(samples);
      expect(segments, hasLength(1));
      expect(segments.single.verdict, WindowVerdict.clearViews);
    });
  });

  group('rainRuns', () {
    RouteCloudSample sample(double progress, double precip) => RouteCloudSample(
      routeProgress: progress,
      latLon: const LatLng(50, 0),
      timeUtc: DateTime.utc(2026, 8, 3, 10),
      cloudLowPercent: 80,
      cloudMidPercent: 0,
      cloudHighPercent: 0,
      precipitationMm: precip,
    );

    test('detects contiguous rainy stretches above the threshold', () {
      final runs = FlightWeatherVerdictPolicy.rainRuns([
        sample(0.1, 0),
        sample(0.3, 1.2),
        sample(0.5, 2.0),
        sample(0.7, 0.1), // dry noise below threshold
        sample(0.9, 0.8),
      ]);

      expect(runs, hasLength(2));
      expect(runs.first.startProgress, 0.3);
      expect(runs.first.endProgress, 0.5);
      expect(runs.last.startProgress, 0.9);
    });

    test('dry route yields no runs', () {
      expect(
        FlightWeatherVerdictPolicy.rainRuns([sample(0.5, 0.2)]),
        isEmpty,
      );
    });
  });
}
