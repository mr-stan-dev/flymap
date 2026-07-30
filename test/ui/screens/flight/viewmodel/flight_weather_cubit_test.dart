import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/flight_weather_store.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/usecase/fetch_flight_weather_use_case.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_weather_cubit.dart';
import 'package:latlong2/latlong.dart';

class _FakeStore extends FlightWeatherStore {
  FlightWeather? stored;
  FlightWeather? saved;

  @override
  Future<FlightWeather?> load(String flightId) async => stored;

  @override
  Future<void> save(String flightId, FlightWeather weather) async {
    saved = weather;
  }

  @override
  Future<void> delete(String flightId) async {
    stored = null;
  }
}

class _FakeUseCase implements FetchFlightWeatherUseCase {
  _FakeUseCase({this.result, this.error});

  FlightWeather? result;
  Object? error;
  int calls = 0;

  @override
  Future<FlightWeather> call({
    required FlightRoute route,
    FlightSchedule? schedule,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result!;
  }
}

FlightWeather _weather({DateTime? fetchedAt}) {
  return FlightWeather(
    departure: AirportWeather(
      timeUtc: DateTime.utc(2026, 8, 3, 8),
      utcOffsetMinutes: 60,
    ),
    arrival: AirportWeather(
      timeUtc: DateTime.utc(2026, 8, 3, 11),
      utcOffsetMinutes: 120,
    ),
    samples: const [],
    fetchedAt: fetchedAt ?? DateTime.now().toUtc(),
    isTimeEstimated: false,
  );
}

Flight _flight({bool dateless = false}) {
  const departure = Airport(
    name: 'London Heathrow',
    city: 'London',
    countryCode: 'GB',
    latLon: LatLng(51.47, -0.45),
    iataCode: 'LHR',
    icaoCode: 'EGLL',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Rome Fiumicino',
    city: 'Rome',
    countryCode: 'IT',
    latLon: LatLng(41.8, 12.24),
    iataCode: 'FCO',
    icaoCode: 'LIRF',
    wikipediaUrl: '',
  );
  return Flight(
    id: 'flight-1',
    route: const FlightRoute(
      departure: departure,
      arrival: arrival,
      waypoints: [],
      corridor: [],
    ),
    routeInsights: FlightInfo.empty.routeInsights,
    offlineContent: FlightInfo.empty.offlineContent,
    timestamp: FlightTimestamp(createdAt: DateTime(2026, 7, 1)),
    schedule: dateless
        ? null
        : FlightSchedule.dateOnly(DateTime.now().add(const Duration(days: 2))),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stored forecast shows even with no network path at all', () async {
    final store = _FakeStore()..stored = _weather();
    final cubit = FlightWeatherCubit(
      flight: _flight(),
      useCase: _FakeUseCase(error: StateError('offline')),
      store: store,
    );
    addTearDown(cubit.close);

    await cubit.fetchIfNeeded(hasProAccess: true);

    // Stored data survives the failed refresh; no failure is flagged.
    expect(cubit.state.weather, store.stored);
    expect(cubit.state.failed, isFalse);
  });

  test('fresh stored forecast skips the network entirely', () async {
    final useCase = _FakeUseCase(result: _weather());
    final cubit = FlightWeatherCubit(
      flight: _flight(),
      useCase: useCase,
      store: _FakeStore()..stored = _weather(),
    );
    addTearDown(cubit.close);

    await cubit.fetchIfNeeded(hasProAccess: true);

    expect(useCase.calls, 0);
  });

  test('stale stored forecast refreshes and stores the new fetch', () async {
    final fresh = _weather();
    final store = _FakeStore()
      ..stored = _weather(
        fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 10)),
      );
    final cubit = FlightWeatherCubit(
      flight: _flight(),
      useCase: _FakeUseCase(result: fresh),
      store: store,
    );
    addTearDown(cubit.close);

    await cubit.fetchIfNeeded(hasProAccess: true);

    expect(cubit.state.weather, fresh);
    expect(store.saved, fresh);
  });

  test('nothing stored and fetch fails -> failed state', () async {
    final cubit = FlightWeatherCubit(
      flight: _flight(),
      useCase: _FakeUseCase(error: StateError('offline')),
      store: _FakeStore(),
    );
    addTearDown(cubit.close);

    await cubit.fetchIfNeeded(hasProAccess: true);

    expect(cubit.state.weather, isNull);
    expect(cubit.state.failed, isTrue);
  });

  test('no Pro access never touches store or network', () async {
    final useCase = _FakeUseCase(result: _weather());
    final cubit = FlightWeatherCubit(
      flight: _flight(),
      useCase: useCase,
      store: _FakeStore()..stored = _weather(),
    );
    addTearDown(cubit.close);

    await cubit.fetchIfNeeded(hasProAccess: false);

    expect(useCase.calls, 0);
    expect(cubit.state.weather, isNull);
  });

  test('dateless flight skips the fetch (no today-estimate)', () async {
    final useCase = _FakeUseCase(result: _weather());
    final cubit = FlightWeatherCubit(
      flight: _flight(dateless: true),
      useCase: useCase,
      store: _FakeStore(),
    );
    addTearDown(cubit.close);

    await cubit.fetchIfNeeded(hasProAccess: true);

    expect(useCase.calls, 0);
    expect(cubit.state.weather, isNull);
  });

  test('applySchedule sets a date and fetches', () async {
    final useCase = _FakeUseCase(result: _weather());
    final store = _FakeStore();
    final cubit = FlightWeatherCubit(
      flight: _flight(dateless: true),
      useCase: useCase,
      store: store,
    );
    addTearDown(cubit.close);

    await cubit.applySchedule(
      FlightSchedule.dateOnly(DateTime.now().add(const Duration(days: 3))),
      hasProAccess: true,
    );

    expect(useCase.calls, 1);
    expect(cubit.state.weather, isNotNull);
    expect(store.saved, isNotNull);
  });
}
