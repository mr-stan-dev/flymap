import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/met_norway_api.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';
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
        departure: ZonedInstant(
          utc: DateTime.utc(2026, 8, 3, 8),
          offsetMinutes: 120,
        ),
        arrival: ZonedInstant(
          utc: DateTime.utc(2026, 8, 3, 10, 40),
          offsetMinutes: 180,
        ),
      ),
    );

    expect(weather.isTimeEstimated, isFalse);
    expect(weather.departure.temperatureC, 20.0);
    expect(weather.departure.utcOffsetMinutes, 120);
    // Real STA and the arrival airport's own offset flow through.
    expect(weather.arrival.timeUtc, DateTime.utc(2026, 8, 3, 10, 40));
    expect(weather.arrival.utcOffsetMinutes, 180);
    expect(weather.samples.length, greaterThanOrEqualTo(5));
    expect(weather.samples.length, lessThanOrEqualTo(20));
    // The two airports now anchor the cloud field (progress 0 and 1) so the
    // map matches their cards; they use the same forecasts, no extra requests.
    expect(weather.samples.first.routeProgress, 0);
    expect(weather.samples.last.routeProgress, 1);
    // Every corridor sample (airports included) + the area grid is one request.
    expect(weather.areaSamples, isNotEmpty);
    expect(
      requestLog.length,
      weather.samples.length + weather.areaSamples.length,
    );
    // Airport rings: 4 extra area samples pinned to each endpoint, so the
    // field's nearest-neighbor blend has local consensus at the airports.
    expect(
      weather.areaSamples.where((s) => s.routeProgress == 0).length,
      greaterThanOrEqualTo(4),
    );
    expect(
      weather.areaSamples.where((s) => s.routeProgress == 1).length,
      greaterThanOrEqualTo(4),
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
    // The first sample is the departure airport at STD; the rest come after.
    expect(weather.samples.first.timeUtc, DateTime.utc(2026, 8, 3, 8));

    // Sample coordinates progress along the route.
    for (var i = 1; i < weather.samples.length; i++) {
      expect(
        weather.samples[i].latLon.longitude,
        greaterThan(weather.samples[i - 1].latLon.longitude),
      );
    }

    // Each sample carries its flight-window timeline (dep-1h .. arr+1h,
    // bracketed by one entry beyond each edge) from the same single fetch —
    // this is what animates the cloud field.
    final sample = weather.samples.first;
    expect(sample.timeline, isNotEmpty);
    expect(
      sample.timeline.first.timeUtc.isBefore(sample.timeline.last.timeUtc),
      isTrue,
    );
    // Brackets: the timeline reaches past both window edges (window is
    // 07:00..11:40 here, hourly data -> 06:00 and 12:00 brackets).
    expect(
      sample.timeline.first.timeUtc.isBefore(DateTime.utc(2026, 8, 3, 7)),
      isTrue,
    );
    expect(
      sample.timeline.last.timeUtc.isAfter(DateTime.utc(2026, 8, 3, 11, 40)),
      isTrue,
    );
    // Interpolation midway between two hourly slices stays within range.
    final mid = sample.timeline.first.timeUtc.add(
      const Duration(minutes: 30),
    );
    expect(sample.hiddenAt(mid), sample.timeline.first.groundHiddenPercent);
  });

  test('6-hourly horizon still yields a >=2-slice bracketed timeline',
      () async {
    // 3+ days out MET serves 6-hourly entries only; the flight window
    // (dep-1h..arr+1h) then contains at most ONE entry. Regression for the
    // frozen-animation / map-contradicts-cards bug: brackets must pull in
    // the nearest entry on each side so hiddenAt() interpolates.
    final client = MockClient((request) async {
      final timeseries = [
        for (final hour in [0, 6, 12, 18])
          {
            'time': '2026-08-06T${hour.toString().padLeft(2, '0')}:00:00Z',
            'data': {
              'instant': {
                'details': {
                  'air_temperature': 20.0,
                  'wind_speed': 5.0,
                  'cloud_area_fraction': 50.0,
                  'cloud_area_fraction_low': hour == 6
                      ? 20.0
                      : hour == 12
                      ? 80.0
                      : 10.0,
                  'cloud_area_fraction_medium': 0.0,
                  'cloud_area_fraction_high': 0.0,
                },
              },
              'next_6_hours': {
                'summary': {'symbol_code': 'cloudy'},
                'details': {'precipitation_amount': 3.0},
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
    final useCase = FetchFlightWeatherUseCase(
      api: MetNorwayApi(httpClient: client),
    );

    final weather = await useCase.call(
      route: _route(),
      schedule: FlightSchedule(
        travelDate: DateTime(2026, 8, 6),
        departure: ZonedInstant(
          utc: DateTime.utc(2026, 8, 6, 8),
          offsetMinutes: 0,
        ),
        arrival: ZonedInstant(
          utc: DateTime.utc(2026, 8, 6, 10, 40),
          offsetMinutes: 0,
        ),
      ),
    );

    // Window 07:00..11:40 holds no 6-hourly entry; brackets 06:00 + 12:00.
    final sample = weather.samples.first;
    expect(sample.timeline, hasLength(2));
    expect(sample.timeline.first.timeUtc, DateTime.utc(2026, 8, 6, 6));
    expect(sample.timeline.last.timeUtc, DateTime.utc(2026, 8, 6, 12));
    // The field now evolves across the flight instead of freezing on 12:00.
    expect(
      sample.hiddenAt(DateTime.utc(2026, 8, 6, 9)),
      closeTo(50, 0.001),
    );
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

  test('date-only schedules use airport timezones for noon and offsets',
      () async {
    final useCase = FetchFlightWeatherUseCase(
      api: MetNorwayApi(httpClient: _fakeMetNorway(requestLog: [])),
      timezoneService: AirportTimezoneService(
        airportsDatabase: AirportsDatabase.test(
          seedTimezones: {'AAAA': 'Europe/Berlin', 'BBBB': 'Asia/Tokyo'},
        ),
      ),
    );

    final weather = await useCase.call(
      route: _route(),
      schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 3)),
    );

    expect(weather.isTimeEstimated, isTrue);
    // True local noon at the departure airport (Berlin, CEST): 10:00 UTC.
    expect(weather.departure.timeUtc, DateTime.utc(2026, 8, 3, 10));
    expect(weather.departure.utcOffsetMinutes, 120);
    // Arrival offset from ITS airport timezone, not the departure's.
    expect(weather.arrival.utcOffsetMinutes, 540);
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
