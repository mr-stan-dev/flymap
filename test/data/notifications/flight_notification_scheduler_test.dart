import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/notifications/flight_notification_scheduler.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/policy/forecast_notification_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/forecast_notification_prefs.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordedNotification {
  const _RecordedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.whenUtc,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime whenUtc;
  final String payload;
}

class _FakeGateway implements ScheduledNotificationsGateway {
  final scheduled = <_RecordedNotification>[];
  final cancelled = <int>[];

  @override
  Future<void> initialize({
    required void Function(String? payload) onNotificationTapped,
  }) async {}

  @override
  Future<String?> takeLaunchPayload() async => null;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime whenUtc,
    required String payload,
  }) async {
    scheduled.add(
      _RecordedNotification(
        id: id,
        title: title,
        body: body,
        whenUtc: whenUtc,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }
}

class _FakePermissionService extends NotificationPermissionService {
  bool granted = true;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async => granted;
}

class _FakeFlightRepository implements FlightRepository {
  _FakeFlightRepository({this.flights = const []});

  final List<Flight> flights;

  @override
  Future<List<Flight>> getAllFlights() async => flights;

  @override
  Future<Flight?> getFlightById(String flightId) async {
    for (final flight in flights) {
      if (flight.id == flightId) return flight;
    }
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Flight _flight({
  String id = 'flight-1',
  FlightSchedule? schedule,
  String accessTier = Flight.accessTierPro,
}) {
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
    id: id,
    route: const FlightRoute(
      departure: departure,
      arrival: arrival,
      waypoints: [],
      corridor: [],
    ),
    routeInsights: FlightInfo.empty.routeInsights,
    offlineContent: FlightInfo.empty.offlineContent,
    timestamp: FlightTimestamp(createdAt: DateTime(2026, 7, 1)),
    flightAccessTier: accessTier,
    schedule: schedule,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  late _FakeGateway gateway;
  late _FakePermissionService permission;

  // "Now" fixed well before the fixture travel date.
  final now = DateTime.utc(2026, 7, 30, 12);

  FlightNotificationScheduler scheduler({List<Flight> flights = const []}) {
    return FlightNotificationScheduler(
      gateway: gateway,
      timezoneService: AirportTimezoneService(
        airportsDatabase: AirportsDatabase.test(
          seedTimezones: {'EGLL': 'Europe/London'},
        ),
      ),
      permissionService: permission,
      prefs: ForecastNotificationPrefs(),
      flightRepository: _FakeFlightRepository(flights: flights),
      now: () => now,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    gateway = _FakeGateway();
    permission = _FakePermissionService();
  });

  test('schedules both alerts at airport-local times', () async {
    final flight = _flight(
      schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 15)),
    );

    await scheduler().syncForFlight(flight);

    expect(gateway.scheduled, hasLength(2));
    final ready = gateway.scheduled.firstWhere(
      (n) =>
          n.id ==
          FlightNotificationScheduler.notificationId(
            flight.id,
            ForecastNotificationType.forecastReady,
          ),
    );
    final updated = gateway.scheduled.firstWhere(
      (n) =>
          n.id ==
          FlightNotificationScheduler.notificationId(
            flight.id,
            ForecastNotificationType.forecastUpdated,
          ),
    );
    // Aug 9 10:00 London (BST, UTC+1) -> 09:00 UTC.
    expect(ready.whenUtc, DateTime.utc(2026, 8, 9, 9));
    // Aug 14 18:00 London -> 17:00 UTC.
    expect(updated.whenUtc, DateTime.utc(2026, 8, 14, 17));
    expect(ready.payload, flight.id);
    expect(ready.body, contains('LHR → FCO'));
  });

  test('free-tier flights are never scheduled', () async {
    final flight = _flight(
      schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 15)),
      accessTier: Flight.accessTierBasic,
    );

    await scheduler().syncForFlight(flight);

    expect(gateway.scheduled, isEmpty);
  });

  test('missing permission schedules nothing', () async {
    permission.granted = false;

    await scheduler().syncForFlight(
      _flight(schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 15))),
    );

    expect(gateway.scheduled, isEmpty);
  });

  test('a disabled toggle mutes only its alert', () async {
    await ForecastNotificationPrefs().setReadyEnabled(false);

    await scheduler().syncForFlight(
      _flight(schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 15))),
    );

    expect(gateway.scheduled, hasLength(1));
    expect(
      gateway.scheduled.single.id,
      FlightNotificationScheduler.notificationId(
        'flight-1',
        ForecastNotificationType.forecastUpdated,
      ),
    );
  });

  test('past fire times are skipped (flight created inside the window)',
      () async {
    // Aug 2: T-6d is Jul 27 (past); T-1d Aug 1 18:00 is future.
    await scheduler().syncForFlight(
      _flight(schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 2))),
    );

    expect(gateway.scheduled, hasLength(1));
    expect(
      gateway.scheduled.single.id,
      FlightNotificationScheduler.notificationId(
        'flight-1',
        ForecastNotificationType.forecastUpdated,
      ),
    );
  });

  test('sync clears both slots first; dateless flights end up empty',
      () async {
    final flight = _flight(schedule: null);

    await scheduler().syncForFlight(flight);

    expect(gateway.scheduled, isEmpty);
    expect(gateway.cancelled, hasLength(2));
  });

  test('resyncAll walks every saved flight', () async {
    final flights = [
      _flight(id: 'a', schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 15))),
      _flight(id: 'b', schedule: FlightSchedule.dateOnly(DateTime(2026, 8, 20))),
    ];

    await scheduler(flights: flights).resyncAll();

    expect(gateway.scheduled, hasLength(4));
    expect(
      gateway.scheduled.map((n) => n.payload).toSet(),
      {'a', 'b'},
    );
  });
}
