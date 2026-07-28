import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/met_norway_api.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/usecase/fetch_flight_weather_use_case.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

/// Serves a synthetic hourly timeseries covering 2026-08-03 00:00..23:00 UTC
/// for every coordinate; cloud cover encodes the longitude so tests can tell
/// samples apart.
http.Client _fakeMetNorway({required List<Uri> requestLog}) {
  return MockClient((request) async {
    requestLog.add(request.url);
    expect(request.headers['User-Agent'], contains('contact:'));
    final lon = double.parse(request.url.queryParameters['lon']!);
    final timeseries = [
      for (var hour = 0; hour < 24; hour++)
        {
          'time': '2026-08-03T${hour.toString().padLeft(2, '0')}:00:00Z',
          'data': {
            'instant': {
              'details': {
                'air_temperature': 20.0,
                'wind_speed': 5.0,
                'cloud_area_fraction': 50.0,
                'cloud_area_fraction_low': lon.abs() % 100,
                'cloud_area_fraction_medium': 0.0,
                'cloud_area_fraction_high': 10.0,
              },
            },
            'next_1_hours': {
              'summary': {'symbol_code': 'partlycloudy_day'},
              'details': {'precipitation_amount': 0.0},
            },
          },
        },
    ];
    return http.Response(
      jsonEncode({
        'properties': {'timeseries': timeseries},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

FlightRoute _route() {
  const departure = Airport(
    name: 'A',
    city: 'A',
    countryCode: 'DE',
    latLon: LatLng(50, 0),
    iataCode: 'AAA',
    icaoCode: 'AAAA',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'B',
    city: 'B',
    countryCode: 'ES',
    latLon: LatLng(50, 20),
    iataCode: 'BBB',
    icaoCode: 'BBBB',
    wikipediaUrl: '',
  );
  return const FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [],
    corridor: [],
  );
}

void main() {
  test('fetches airports plus spaced samples with overhead times', () async {
    final requestLog = <Uri>[];
    final useCase = FetchFlightWeatherUseCase(
      api: MetNorwayApi(httpClient: _fakeMetNorway(requestLog: requestLog)),
    );

    final weather = await useCase.call(
      route: _route(),
      schedule: FlightSchedule(
        travelDate: DateTime(2026, 8, 3),
        scheduledDepartureUtc: DateTime.utc(2026, 8, 3, 8),
        departureUtcOffsetMinutes: 120,
      ),
    );

    expect(weather.isTimeEstimated, isFalse);
    expect(weather.departure.temperatureC, 20.0);
    expect(weather.departure.utcOffsetMinutes, 120);
    expect(weather.samples.length, greaterThanOrEqualTo(5));
    expect(weather.samples.length, lessThanOrEqualTo(20));
    // Airports + corridor + the full-card area grid, each one request.
    expect(weather.areaSamples, isNotEmpty);
    expect(
      requestLog.length,
      2 + weather.samples.length + weather.areaSamples.length,
    );
    // The grid stays sparse — the whole fetch keeps a sane request budget.
    expect(requestLog.length, lessThanOrEqualTo(80));

    // Overhead times increase monotonically from STD toward arrival.
    for (var i = 1; i < weather.samples.length; i++) {
      expect(
        weather.samples[i].timeUtc.isAfter(weather.samples[i - 1].timeUtc),
        isTrue,
      );
    }
    expect(
      weather.samples.first.timeUtc.isAfter(DateTime.utc(2026, 8, 3, 8)),
      isTrue,
    );

    // Sample coordinates progress along the route.
    for (var i = 1; i < weather.samples.length; i++) {
      expect(
        weather.samples[i].latLon.longitude,
        greaterThan(weather.samples[i - 1].latLon.longitude),
      );
    }

    // Each sample carries its flight-window timeline (dep-1h .. arr+1h)
    // from the same single fetch — this is what animates the cloud field.
    final sample = weather.samples.first;
    expect(sample.timeline, isNotEmpty);
    expect(
      sample.timeline.first.timeUtc.isBefore(sample.timeline.last.timeUtc),
      isTrue,
    );
    expect(
      sample.timeline.first.timeUtc.isAfter(
        DateTime.utc(2026, 8, 3, 8).subtract(const Duration(hours: 2)),
      ),
      isTrue,
    );
    // Interpolation midway between two hourly slices stays within range.
    final mid = sample.timeline.first.timeUtc.add(
      const Duration(minutes: 30),
    );
    expect(sample.hiddenAt(mid), sample.timeline.first.groundHiddenPercent);
  });

  test('marks times estimated when no schedule exists', () async {
    final useCase = FetchFlightWeatherUseCase(
      api: MetNorwayApi(httpClient: _fakeMetNorway(requestLog: [])),
    );

    // Dateless flights get "now + 2h" — the fake serves 2026-08-03 only, so
    // pin the date via travelDate to keep the fake in range.
    final weather = await useCase.call(
      route: _route(),
      schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 3)),
    );

    expect(weather.isTimeEstimated, isTrue);
  });

  test('throws when both airport forecasts are unavailable', () async {
    final client = MockClient((request) async => http.Response('nope', 500));
    final useCase = FetchFlightWeatherUseCase(
      api: MetNorwayApi(httpClient: client),
    );

    await expectLater(
      useCase.call(
        route: _route(),
        schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 3)),
      ),
      throwsA(isA<WeatherUnavailableException>()),
    );
  });
}
