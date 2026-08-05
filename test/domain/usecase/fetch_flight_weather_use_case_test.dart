import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/weather_attribution.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';
import 'package:flymap/domain/provider/weather_forecast_provider.dart';
import 'package:flymap/domain/usecase/fetch_flight_weather_use_case.dart';
import 'package:latlong2/latlong.dart';

class _FakeWeatherForecastProvider implements WeatherForecastProvider {
  _FakeWeatherForecastProvider({
    this.hours = const [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
    ],
    this.unavailable = false,
    this.sixHourlyClouds = false,
  });

  final List<int> hours;
  final bool unavailable;
  final bool sixHourlyClouds;
  int callCount = 0;
  int requestCount = 0;

  @override
  Future<WeatherForecastBatch> forecastBatch({
    required List<WeatherForecastRequest> requests,
    required DateTime windowStartUtc,
    required DateTime windowEndUtc,
  }) async {
    callCount++;
    requestCount += requests.length;
    return WeatherForecastBatch(
      seriesByRequest: [
        for (final request in requests)
          unavailable ? const [] : _series(request),
      ],
      retrievedAtUtc: DateTime.utc(2026, 8, 3),
      attribution: WeatherAttribution.metNorway,
    );
  }

  List<WeatherForecastPoint> _series(WeatherForecastRequest request) {
    final target = request.targetTimeUtc.toUtc();
    final date = DateTime.utc(target.year, target.month, target.day);
    return [
      for (final hour in hours)
        WeatherForecastPoint(
          timeUtc: date.add(Duration(hours: hour)),
          temperatureC: 20,
          windSpeedMs: 5,
          cloudCoverPercent: 50,
          cloudLowPercent: sixHourlyClouds
              ? hour == 6
                    ? 20
                    : hour == 12
                    ? 80
                    : 10
              : request.coordinate.longitude.abs() % 100,
          cloudMidPercent: 0,
          cloudHighPercent: sixHourlyClouds ? 0 : 10,
          precipitationMm: sixHourlyClouds ? 0.5 : 0,
          symbolCode: sixHourlyClouds ? 'cloudy' : 'partlycloudy_day',
        ),
    ];
  }
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
    final provider = _FakeWeatherForecastProvider();
    final useCase = FetchFlightWeatherUseCase(provider: provider);

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
    // Every corridor sample (airports included) + area sample is included in
    // one provider call, preserving batching through the domain boundary.
    expect(weather.areaSamples, isNotEmpty);
    expect(provider.callCount, 1);
    expect(
      provider.requestCount,
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
    expect(provider.requestCount, lessThanOrEqualTo(80));

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
    final mid = sample.timeline.first.timeUtc.add(const Duration(minutes: 30));
    expect(sample.hiddenAt(mid), sample.timeline.first.groundHiddenPercent);
  });

  test(
    '6-hourly horizon still yields a >=2-slice bracketed timeline',
    () async {
      // A provider may serve 6-hourly entries at the longer horizon; the window
      // (dep-1h..arr+1h) then contains at most ONE entry. Regression for the
      // frozen-animation / map-contradicts-cards bug: brackets must pull in
      // the nearest entry on each side so hiddenAt() interpolates.
      final useCase = FetchFlightWeatherUseCase(
        provider: _FakeWeatherForecastProvider(
          hours: const [0, 6, 12, 18],
          sixHourlyClouds: true,
        ),
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
      expect(sample.hiddenAt(DateTime.utc(2026, 8, 6, 9)), closeTo(50, 0.001));
    },
  );

  test('marks user-entered times as estimated', () async {
    final useCase = FetchFlightWeatherUseCase(
      provider: _FakeWeatherForecastProvider(),
      now: () => DateTime.utc(2026, 8, 3),
    );

    final weather = await useCase.call(
      route: _route(),
      schedule: FlightSchedule.approximate(
        DateTime(2026, 8, 3),
        departureTime: const ApproximateDepartureTime(hour: 12, minute: 0),
      ),
    );

    expect(weather.isTimeEstimated, isTrue);
  });

  test('date-only schedules are rejected instead of assuming noon', () async {
    final useCase = FetchFlightWeatherUseCase(
      provider: _FakeWeatherForecastProvider(),
      timezoneService: AirportTimezoneService(
        airportsDatabase: AirportsDatabase.test(
          seedTimezones: {'AAAA': 'Europe/Berlin', 'BBBB': 'Asia/Tokyo'},
        ),
      ),
      now: () => DateTime.utc(2026, 8, 3),
    );

    await expectLater(
      useCase.call(
        route: _route(),
        schedule: FlightSchedule(travelDate: DateTime(2026, 8, 3)),
      ),
      throwsA(isA<WeatherDepartureTimeRequiredException>()),
    );
  });

  test('approximate period uses its departure-airport local hour', () async {
    final useCase = FetchFlightWeatherUseCase(
      provider: _FakeWeatherForecastProvider(),
      timezoneService: AirportTimezoneService(
        airportsDatabase: AirportsDatabase.test(
          seedTimezones: {'AAAA': 'Europe/Berlin', 'BBBB': 'Asia/Tokyo'},
        ),
      ),
      now: () => DateTime.utc(2026, 8, 3),
    );

    final weather = await useCase.call(
      route: _route(),
      schedule: FlightSchedule.approximate(
        DateTime(2026, 8, 3),
        departureTime: ApproximateDepartureTime.forPeriod(
          ApproximateDeparturePeriod.afternoon,
        ),
      ),
    );

    // Afternoon is represented by 14:00 local; Berlin is UTC+2 in August.
    expect(weather.departure.timeUtc, DateTime.utc(2026, 8, 3, 12));
    expect(weather.isTimeEstimated, isTrue);
  });

  test('specific time preserves minutes in the departure timezone', () async {
    final useCase = FetchFlightWeatherUseCase(
      provider: _FakeWeatherForecastProvider(),
      timezoneService: AirportTimezoneService(
        airportsDatabase: AirportsDatabase.test(
          seedTimezones: {'AAAA': 'Europe/Berlin', 'BBBB': 'Asia/Tokyo'},
        ),
      ),
      now: () => DateTime.utc(2026, 8, 3),
    );

    final weather = await useCase.call(
      route: _route(),
      schedule: FlightSchedule.approximate(
        DateTime(2026, 8, 3),
        departureTime: const ApproximateDepartureTime(hour: 14, minute: 37),
      ),
    );

    expect(weather.departure.timeUtc, DateTime.utc(2026, 8, 3, 12, 37));
    expect(weather.isTimeEstimated, isTrue);
  });

  test('late Today estimate clamps to now plus 30 minutes', () async {
    final useCase = FetchFlightWeatherUseCase(
      provider: _FakeWeatherForecastProvider(),
      timezoneService: AirportTimezoneService(
        airportsDatabase: AirportsDatabase.test(
          seedTimezones: {'AAAA': 'Europe/Berlin', 'BBBB': 'Europe/Berlin'},
        ),
      ),
      now: () => DateTime.utc(2026, 8, 3, 20),
    );

    final weather = await useCase.call(
      route: _route(),
      schedule: FlightSchedule.approximate(
        DateTime(2026, 8, 3),
        departureTime: const ApproximateDepartureTime(hour: 12, minute: 0),
      ),
    );

    expect(weather.departure.timeUtc, DateTime.utc(2026, 8, 3, 20, 30));
    expect(weather.samples.first.timeUtc, DateTime.utc(2026, 8, 3, 20, 30));
    expect(
      weather.samples.last.timeUtc.isAfter(weather.samples.first.timeUtc),
      isTrue,
    );
  });

  test('throws when both airport forecasts are unavailable', () async {
    final useCase = FetchFlightWeatherUseCase(
      provider: _FakeWeatherForecastProvider(unavailable: true),
    );

    await expectLater(
      useCase.call(
        route: _route(),
        schedule: FlightSchedule.approximate(
          DateTime(2026, 8, 3),
          departureTime: const ApproximateDepartureTime(hour: 12, minute: 0),
        ),
      ),
      throwsA(isA<WeatherUnavailableException>()),
    );
  });
}
