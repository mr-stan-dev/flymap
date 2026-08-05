import 'dart:async';

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
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/subscription_status.dart';
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
  String? launchPayload;
  void Function(String? payload)? onNotificationTapped;

  @override
  Future<void> initialize({
    required void Function(String? payload) onNotificationTapped,
  }) async {
    this.onNotificationTapped = onNotificationTapped;
  }

  @override
  Future<String?> takeLaunchPayload() async => launchPayload;

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

  final shown = <_RecordedNotification>[];

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    shown.add(
      _RecordedNotification(
        id: id,
        title: title,
        body: body,
        whenUtc: DateTime.utc(2000),
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

class _TrackingTimezoneService extends AirportTimezoneService {
  _TrackingTimezoneService() : super(airportsDatabase: AirportsDatabase.test());

  bool ready = false;

  @override
  Future<void> ensureReady() async => ready = true;

  @override
  DateTime? localTimeToUtc(
    Airport airport,
    DateTime date, {
    int hour = 12,
    int minute = 0,
  }) {
    if (!ready) return null;
    return DateTime.utc(date.year, date.month, date.day, hour - 3, minute);
  }
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

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({bool isPro = false})
    : _currentStatus = SubscriptionStatus(
        isPro: isPro,
        entitlementId: 'pro',
        lastUpdatedAt: DateTime.utc(2026),
      );

  final _controller = StreamController<SubscriptionStatus>.broadcast();
  SubscriptionStatus _currentStatus;

  @override
  SubscriptionStatus get currentStatus => _currentStatus;

  @override
  Stream<SubscriptionStatus> get statusStream => _controller.stream;

  @override
  Future<SubscriptionStatus> initialize() async => _currentStatus;

  void setPro(bool isPro) {
    _currentStatus = _currentStatus.copyWith(isPro: isPro);
    _controller.add(_currentStatus);
  }

  Future<void> dispose() => _controller.close();

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

FlightSchedule _manualSchedule(DateTime date) => FlightSchedule.approximate(
  date,
  departureTime: const ApproximateDepartureTime(hour: 12, minute: 0),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  late _FakeGateway gateway;
  late _FakePermissionService permission;

  // "Now" fixed well before the fixture travel date.
  final now = DateTime.utc(2026, 7, 30, 12);

  FlightNotificationScheduler scheduler({
    List<Flight> flights = const [],
    SubscriptionRepository? subscriptionRepository,
    AirportTimezoneService? timezoneService,
  }) {
    return FlightNotificationScheduler(
      gateway: gateway,
      timezoneService:
          timezoneService ??
          AirportTimezoneService(
            airportsDatabase: AirportsDatabase.test(
              seedTimezones: {'EGLL': 'Europe/London'},
            ),
          ),
      permissionService: permission,
      prefs: ForecastNotificationPrefs(),
      flightRepository: _FakeFlightRepository(flights: flights),
      subscriptionRepository: subscriptionRepository,
      now: () => now,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    gateway = _FakeGateway();
    permission = _FakePermissionService();
  });

  test('notification ids are stable deterministic values', () {
    expect(
      FlightNotificationScheduler.notificationId(
        'flight-1',
        ForecastNotificationType.forecastReady,
      ),
      34353666,
    );
    expect(
      FlightNotificationScheduler.notificationId(
        'flight-1',
        ForecastNotificationType.forecastUpdated,
      ),
      34353667,
    );
  });

  test(
    'loads airport timezones before converting notification times',
    () async {
      final timezoneService = _TrackingTimezoneService();
      final flight = _flight(schedule: _manualSchedule(DateTime(2026, 8, 15)));

      await scheduler(timezoneService: timezoneService).syncForFlight(flight);

      expect(timezoneService.ready, isTrue);
      expect(gateway.scheduled, hasLength(2));
      // Tracking service maps 10:00 local to 07:00 UTC. A pre-ready conversion
      // would have returned null and fallen back to the device timezone.
      expect(gateway.scheduled.first.whenUtc, DateTime.utc(2026, 8, 9, 7));
    },
  );

  test('schedules both alerts at airport-local times', () async {
    final flight = _flight(schedule: _manualSchedule(DateTime(2026, 8, 15)));

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
    // Pro flights carry the weather-forecast copy.
    expect(ready.title.toLowerCase(), contains('forecast'));
    expect(updated.title, 'Your flight is tomorrow');
    expect(updated.body, 'LHR → FCO — open Flymap for the latest forecast.');
    expect(updated.body.toLowerCase(), isNot(contains('updated')));
  });

  test('free-tier flights get plain reminders, not forecast copy', () async {
    final flight = _flight(
      schedule: _manualSchedule(DateTime(2026, 8, 15)),
      accessTier: Flight.accessTierBasic,
    );

    await scheduler().syncForFlight(flight);

    // Same two slots and times as Pro, but the copy is a plain flight nudge
    // with no weather wording.
    expect(gateway.scheduled, hasLength(2));
    final ready = gateway.scheduled.firstWhere(
      (n) =>
          n.id ==
          FlightNotificationScheduler.notificationId(
            flight.id,
            ForecastNotificationType.forecastReady,
          ),
    );
    expect(ready.whenUtc, DateTime.utc(2026, 8, 9, 9));
    expect(ready.payload, flight.id);
    expect(ready.body, contains('LHR → FCO'));
    expect(ready.title.toLowerCase(), isNot(contains('forecast')));
  });

  test(
    'global Pro access gives an existing Basic flight forecast alerts',
    () async {
      final subscriptions = _FakeSubscriptionRepository(isPro: true);
      addTearDown(subscriptions.dispose);
      final flight = _flight(
        schedule: _manualSchedule(DateTime(2026, 8, 15)),
        accessTier: Flight.accessTierBasic,
      );
      final subject = scheduler(subscriptionRepository: subscriptions);

      await subject.syncForFlight(flight);

      expect(subject.hasEffectiveProAccess(flight), isTrue);
      expect(gateway.scheduled, hasLength(2));
      expect(gateway.scheduled.first.title.toLowerCase(), contains('forecast'));
    },
  );

  test(
    'subscription changes resync existing flight notification copy',
    () async {
      final subscriptions = _FakeSubscriptionRepository();
      addTearDown(subscriptions.dispose);
      final flight = _flight(
        schedule: _manualSchedule(DateTime(2026, 8, 15)),
        accessTier: Flight.accessTierBasic,
      );
      final subject = scheduler(
        flights: [flight],
        subscriptionRepository: subscriptions,
      );
      await subject.initialize();
      await subject.resyncAll();
      expect(gateway.scheduled.first.title, 'Your flight is coming up');
      gateway.scheduled.clear();

      subscriptions.setPro(true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(gateway.scheduled, hasLength(2));
      expect(gateway.scheduled.first.title.toLowerCase(), contains('forecast'));
    },
  );

  test('permission granted in system settings resyncs on app resume', () async {
    permission.granted = false;
    final flight = _flight(schedule: _manualSchedule(DateTime(2026, 8, 15)));
    final subject = scheduler(flights: [flight]);
    await subject.initialize();
    await subject.resyncAll();
    expect(gateway.scheduled, isEmpty);

    permission.granted = true;
    await subject.handleAppResumed();
    expect(gateway.scheduled, hasLength(2));

    await subject.handleAppResumed();
    expect(gateway.scheduled, hasLength(2));
  });

  test('cold-start notification payload opens its saved flight', () async {
    final flight = _flight(schedule: _manualSchedule(DateTime(2026, 8, 15)));
    gateway.launchPayload = flight.id;
    final subject = scheduler(flights: [flight]);
    Flight? opened;
    subject.onOpenFlight = (flight) => opened = flight;

    await subject.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(opened, flight);
  });

  test(
    'sendPreview fires immediately with the flight copy and payload',
    () async {
      final flight = _flight(schedule: _manualSchedule(DateTime(2026, 8, 15)));

      await scheduler().sendPreview(
        flight,
        ForecastNotificationType.forecastReady,
      );

      // Shown now (not scheduled), carries the route copy and deep-link payload.
      expect(gateway.scheduled, isEmpty);
      expect(gateway.shown, hasLength(1));
      expect(gateway.shown.single.payload, flight.id);
      expect(gateway.shown.single.body, contains('LHR → FCO'));
    },
  );

  test('missing permission schedules nothing', () async {
    permission.granted = false;

    await scheduler().syncForFlight(
      _flight(schedule: _manualSchedule(DateTime(2026, 8, 15))),
    );

    expect(gateway.scheduled, isEmpty);
  });

  test('a disabled toggle mutes only its alert', () async {
    await ForecastNotificationPrefs().setReadyEnabled(false);

    await scheduler().syncForFlight(
      _flight(schedule: _manualSchedule(DateTime(2026, 8, 15))),
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

  test(
    'past fire times are skipped (flight created inside the window)',
    () async {
      // Aug 2: T-6d is Jul 27 (past); T-1d Aug 1 18:00 is future.
      await scheduler().syncForFlight(
        _flight(schedule: _manualSchedule(DateTime(2026, 8, 2))),
      );

      expect(gateway.scheduled, hasLength(1));
      expect(
        gateway.scheduled.single.id,
        FlightNotificationScheduler.notificationId(
          'flight-1',
          ForecastNotificationType.forecastUpdated,
        ),
      );
    },
  );

  test('sync clears both slots first; dateless flights end up empty', () async {
    final flight = _flight(schedule: null);

    await scheduler().syncForFlight(flight);

    expect(gateway.scheduled, isEmpty);
    expect(gateway.cancelled, hasLength(2));
  });

  test('resyncAll walks every saved flight', () async {
    final flights = [
      _flight(id: 'a', schedule: _manualSchedule(DateTime(2026, 8, 15))),
      _flight(id: 'b', schedule: _manualSchedule(DateTime(2026, 8, 20))),
    ];

    await scheduler(flights: flights).resyncAll();

    expect(gateway.scheduled, hasLength(4));
    expect(gateway.scheduled.map((n) => n.payload).toSet(), {'a', 'b'});
  });
}
