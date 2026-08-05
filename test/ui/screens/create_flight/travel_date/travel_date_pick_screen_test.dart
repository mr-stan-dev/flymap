import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/travel_date/flight_notification_permission_prompt.dart';
import 'package:flymap/ui/screens/create_flight/travel_date/travel_date_pick_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

const _departure = Airport(
  name: 'Bristol',
  city: 'Bristol',
  countryCode: 'GB',
  latLon: LatLng(51.38, -2.72),
  iataCode: 'BRS',
  icaoCode: 'EGGD',
  wikipediaUrl: '',
);
const _arrival = Airport(
  name: 'Krakow',
  city: 'Krakow',
  countryCode: 'PL',
  latLon: LatLng(50.08, 19.78),
  iataCode: 'KRK',
  icaoCode: 'EPKK',
  wikipediaUrl: '',
);

Widget _app(TravelDatePickArgs args) {
  return TranslationProvider(
    child: MaterialApp(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: TravelDatePickScreen(args: args),
    ),
  );
}

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('day-before eligibility ends when its reminder time passes', () async {
    final timezoneService = _FixedTimezoneService();
    final schedule = FlightSchedule.approximate(
      DateTime(2026, 8, 7),
      departureTime: const ApproximateDepartureTime(hour: 9, minute: 30),
    );

    expect(
      await FlightNotificationPermissionPrompt.isDayBeforeReminderEligible(
        schedule: schedule,
        departure: _departure,
        timezoneService: timezoneService,
        now: DateTime.utc(2026, 8, 6, 17, 59),
      ),
      isTrue,
    );
    expect(
      await FlightNotificationPermissionPrompt.isDayBeforeReminderEligible(
        schedule: schedule,
        departure: _departure,
        timezoneService: timezoneService,
        now: DateTime.utc(2026, 8, 6, 18),
      ),
      isFalse,
    );
  });

  testWidgets('approximate flight shows four days plus custom date at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const TravelDatePickArgs(departure: _departure, arrival: _arrival)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    // Four days make an even 2x2 grid, with the custom-date row below.
    expect(find.byIcon(Icons.event_rounded), findsNWidgets(4));
    expect(find.byType(GridView), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Pick another date'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pick another date'), findsOneWidget);
    // Continue stays disabled until an explicit choice; the dateless hatch
    // is always available.
    expect(find.text('Skip date & time'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Departure time'), findsOneWidget);
    expect(find.textContaining('forecast'), findsNothing);
    expect(find.text('Morning'), findsNothing);
    expect(find.text('Afternoon'), findsNothing);
    expect(find.text('Evening'), findsNothing);
    expect(find.text('Night'), findsNothing);
    expect(find.text('Set departure time'), findsOneWidget);

    final continueCenter = tester.getCenter(find.text('Continue'));
    final skipCenter = tester.getCenter(find.text('Skip date & time'));
    expect(
      find.ancestor(
        of: find.text('Skip date & time'),
        matching: find.byType(TextButton),
      ),
      findsOneWidget,
    );
    expect(skipCenter.dy, greaterThan(continueCenter.dy));
    expect(skipCenter.dx, closeTo(continueCenter.dx, 0.1));
  });

  testWidgets('date alone keeps Continue disabled', (tester) async {
    await tester.pumpWidget(
      _app(const TravelDatePickArgs(departure: _departure, arrival: _arrival)),
    );

    await tester.tap(find.text('Today'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('skip date & time reaches the preview without a schedule', (
    tester,
  ) async {
    FlightSchedule? receivedSchedule;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const TravelDatePickScreen(
            args: TravelDatePickArgs(departure: _departure, arrival: _arrival),
          ),
        ),
        GoRoute(
          path: AppRouter.flightPreviewRoute,
          builder: (_, state) {
            receivedSchedule =
                (state.extra as Map<String, dynamic>)['schedule']
                    as FlightSchedule?;
            return const Scaffold(body: Text('preview'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp.router(
          locale: AppLocale.en.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Skip date & time'));
    await tester.pumpAndSettle();

    expect(find.text('preview'), findsOneWidget);
    expect(receivedSchedule, isNull);
  });

  testWidgets('specific time picker preserves minute precision in preview', (
    tester,
  ) async {
    FlightSchedule? receivedSchedule;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const TravelDatePickScreen(
            args: TravelDatePickArgs(departure: _departure, arrival: _arrival),
          ),
        ),
        GoRoute(
          path: AppRouter.flightPreviewRoute,
          builder: (_, state) {
            receivedSchedule =
                (state.extra as Map<String, dynamic>)['schedule']
                    as FlightSchedule?;
            return const Scaffold(body: Text('preview'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp.router(
          locale: AppLocale.en.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Today'));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    // Cancelling does not accidentally select the specific-time option.
    await tester.tap(find.text('Set departure time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, 'Set departure time'),
          )
          .selected,
      isFalse,
    );

    await tester.tap(find.text('Set departure time'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).at(1), '37');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Departure · 12:37'), findsOneWidget);
    final selectedChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Departure · 12:37'),
    );
    expect(selectedChip.showCheckmark, isFalse);

    // Tapping the selected chip edits the time instead of clearing it.
    await tester.tap(find.text('Departure · 12:37'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Departure · 12:37'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('preview'), findsOneWidget);
    expect(receivedSchedule?.departure, isNull);
    expect(
      receivedSchedule?.timePrecision,
      FlightScheduleTimePrecision.approximateTime,
    );
    expect(receivedSchedule?.approximateDepartureTime?.period, isNull);
    expect(receivedSchedule?.approximateDepartureTime?.hour, 12);
    expect(receivedSchedule?.approximateDepartureTime?.minute, 37);
  });

  testWidgets(
    'eligible dated flight explains notifications before system request',
    (tester) async {
      final permissionService = _FakePermissionService();
      GetIt.I.registerSingleton<NotificationPermissionService>(
        permissionService,
      );
      GetIt.I.registerSingleton<AirportTimezoneService>(
        _FixedTimezoneService(),
      );
      final router = _previewRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(_routerApp(router));

      // The third option is safely beyond the day-before reminder threshold.
      await tester.tap(find.byIcon(Icons.event_rounded).at(2));
      await tester.pump();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set departure time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Get flight reminders'), findsOneWidget);
      expect(
        find.text(
          'Allow notifications so Flymap can remind you to check the latest '
          'weather before your flight.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.notifications_active_rounded))
            .size,
        48,
      );
      expect(permissionService.requestCount, 0);

      await tester.tap(find.text('Allow notifications'));
      await tester.pumpAndSettle();

      expect(permissionService.requestCount, 1);
      expect(find.text('preview'), findsOneWidget);
    },
  );

  testWidgets('dismissing permission explanation does not continue', (
    tester,
  ) async {
    final permissionService = _FakePermissionService();
    GetIt.I.registerSingleton<NotificationPermissionService>(permissionService);
    GetIt.I.registerSingleton<AirportTimezoneService>(_FixedTimezoneService());
    final router = _previewRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerApp(router));
    await tester.tap(find.byIcon(Icons.event_rounded).at(2));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set departure time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Get flight reminders'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('Get flight reminders'), findsNothing);
    expect(find.text('preview'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    expect(permissionService.requestCount, 0);

    // Continuing again presents the choice again; an explicit decline can
    // proceed to the preview.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('preview'), findsOneWidget);
  });

  testWidgets('skipping date and time never asks for permission', (
    tester,
  ) async {
    final permissionService = _FakePermissionService();
    GetIt.I.registerSingleton<NotificationPermissionService>(permissionService);
    GetIt.I.registerSingleton<AirportTimezoneService>(_FixedTimezoneService());
    final router = _previewRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerApp(router));
    await tester.tap(find.text('Skip date & time'));
    await tester.pumpAndSettle();

    expect(find.text('Get flight reminders'), findsNothing);
    expect(permissionService.statusCheckCount, 0);
    expect(permissionService.requestCount, 0);
    expect(find.text('preview'), findsOneWidget);
  });
}

GoRouter _previewRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const TravelDatePickScreen(
          args: TravelDatePickArgs(departure: _departure, arrival: _arrival),
        ),
      ),
      GoRoute(
        path: AppRouter.flightPreviewRoute,
        builder: (_, _) => const Scaffold(body: Text('preview')),
      ),
    ],
  );
}

Widget _routerApp(GoRouter router) {
  return TranslationProvider(
    child: MaterialApp.router(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    ),
  );
}

class _FakePermissionService extends NotificationPermissionService {
  int statusCheckCount = 0;
  int requestCount = 0;

  @override
  Future<bool> isGranted() async {
    statusCheckCount++;
    return false;
  }

  @override
  Future<bool> request() async {
    requestCount++;
    return true;
  }
}

class _FixedTimezoneService extends AirportTimezoneService {
  _FixedTimezoneService() : super(airportsDatabase: AirportsDatabase.test());

  @override
  Future<void> ensureReady() async {}

  @override
  DateTime? localTimeToUtc(
    Airport airport,
    DateTime date, {
    int hour = 12,
    int minute = 0,
  }) => DateTime.utc(date.year, date.month, date.day, hour, minute);
}
