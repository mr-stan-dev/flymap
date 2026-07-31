import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/data/flight_video/video_encoder.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_service.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/flight_search_weather_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_button.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:latlong2/latlong.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  FlightPreviewState stateWith({
    FlightWeather? weather,
    bool loading = false,
    FlightSchedule? schedule,
  }) {
    return FlightPreviewState.initial().copyWith(
      step: CreateFlightStep.weather,
      flightRoute: _route(),
      flightWeather: weather,
      isWeatherLoading: loading,
      flightSchedule: schedule,
    );
  }

  Widget app(
    FlightPreviewState state, {
    bool isProUser = false,
    VoidCallback? onPickDate,
    VoidCallback? onGoBack,
  }) {
    return TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: FlightSearchWeatherStep(
            state: state,
            isProUser: isProUser,
            onRetry: () {},
            onContinue: () {},
            onPremiumGateTap: () {},
            onPickDate: onPickDate,
            onGoBack: onGoBack,
          ),
        ),
      ),
    );
  }

  testWidgets('renders airport cards and times for Pro users', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(stateWith(weather: _weather()), isProUser: true),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // No layout exceptions and the key content is present.
    expect(tester.takeException(), isNull);
    expect(find.text('Will you see the ground?'), findsOneWidget);
    // Airport cards sit at the top, before the map.
    expect(find.textContaining('AAA'), findsOneWidget);
    expect(find.textContaining('BBB'), findsOneWidget);
    // Times carry their UTC offset instead of a "times are local" footnote.
    expect(
      find.textContaining('GMT+2', findRichText: true),
      findsNWidgets(2),
    );
    // Wind reads as a strength label, not a bare number.
    expect(find.textContaining('Light wind · 4 m/s'), findsNWidgets(2));
  });

  testWidgets(
    'free flights get the blurred demo teaser without any forecast data',
    (tester) async {
      // No FlightWeather in state at all — the cubit never fetched it.
      await tester.pumpWidget(app(stateWith()));
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.text('Will you see the ground?'), findsOneWidget);
      // Real airports on the mocked cards, behind frosted glass.
      expect(find.textContaining('AAA'), findsOneWidget);
      expect(find.textContaining('BBB'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsWidgets);
      // The pitch floats on the glass; the actions sit pinned at the
      // bottom — all visible WITHOUT scrolling.
      expect(
        find.text('Unlock airport weather and clouds along your route'),
        findsOneWidget,
      );
      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(find.text('Continue without weather'), findsOneWidget);
      // The generic Continue is replaced by the paywall anatomy, and no
      // loading/retry UI leaks through.
      expect(find.text('Continue'), findsNothing);
      expect(find.text('Retry'), findsNothing);
    },
  );

  testWidgets('shows the cloud animation instead of the gate for Pro', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(stateWith(weather: _weather()), isProUser: true),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('Upgrade to Pro'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('app-bar share icon opens the sheet with both formats', (
    tester,
  ) async {
    GetIt.I.registerSingleton<WeatherShareService>(
      WeatherShareService(
        mapApi: MapboxStaticImageApi(
          httpClient: MockClient((_) async => http.Response('nope', 500)),
          accessToken: 'test',
        ),
        encoder: _NoopEncoder(),
      ),
    );
    addTearDown(() => GetIt.I.unregister<WeatherShareService>());

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: AppLocale.en.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            appBar: AppBar(
              actions: [
                WeatherShareButton(
                  route: _route(),
                  weather: _weather(),
                  verdictEmoji: '☀️',
                  verdictTitle: 'Clear views',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.share_rounded));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Share as image'), findsOneWidget);
    expect(find.text('Share as video'), findsOneWidget);
  });

  testWidgets('step body carries no share entry anymore', (tester) async {
    await tester.pumpWidget(
      app(stateWith(weather: _weather()), isProUser: true),
    );
    expect(find.text('Share'), findsNothing);
    expect(find.byIcon(Icons.share_rounded), findsNothing);
  });

  testWidgets('date-only flights never display the internal noon estimate', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(stateWith(weather: _weather(isTimeEstimated: true)), isProUser: true),
    );

    expect(tester.takeException(), isNull);
    // 10:00 local = the noon-ish estimate; the clock must not be shown.
    expect(find.textContaining('10:00', findRichText: true), findsNothing);
    expect(find.textContaining('(tomorrow)'), findsNothing);
  });

  testWidgets('failed load shows retry and keeps Continue for Pro', (
    tester,
  ) async {
    // A failed load implies a date was set (the fetch is gated on one);
    // without a date the step shows the "pick a date" prompt instead.
    final schedule = FlightSchedule.dateOnly(
      DateTime.now().add(const Duration(days: 2)),
    );
    await tester.pumpWidget(
      app(stateWith(schedule: schedule), isProUser: true),
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('dateless approximate flight prompts for a date', (tester) async {
    await tester.pumpWidget(
      app(stateWith(), isProUser: true, onPickDate: () {}),
    );

    expect(find.text('Pick a date'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('dateless real flight explains and offers a go-back shortcut', (
    tester,
  ) async {
    var wentBack = false;
    await tester.pumpWidget(
      app(stateWith(), isProUser: true, onGoBack: () => wentBack = true),
    );

    // No inline picker for real flights, just the explanation + shortcut.
    expect(find.text('Pick a date'), findsNothing);
    expect(find.text('Go back to pick a date'), findsOneWidget);

    await tester.tap(find.text('Go back to pick a date'));
    expect(wentBack, isTrue);
  });

  testWidgets(
    'far-future flights explain the forecast horizon instead of failing',
    (tester) async {
      final schedule = FlightSchedule.dateOnly(
        DateTime.now().add(const Duration(days: 60)),
      );
      await tester.pumpWidget(
        app(stateWith(schedule: schedule), isProUser: true),
      );
      await tester.pump();

      expect(
        find.text("It's too early for a reliable forecast"),
        findsOneWidget,
      );
      expect(find.textContaining('7 days ahead'), findsOneWidget);
      // Retry would be a lie — nothing failed, nothing to retry.
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Continue without weather'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      // No permission service registered -> the notification row stays
      // hidden rather than nagging blindly.
      expect(find.byType(Switch), findsNothing);
    },
  );

  testWidgets(
    'missing notification permission shows the toggle until granted',
    (tester) async {
      final service = _FakeNotificationPermissionService();
      GetIt.I.registerSingleton<NotificationPermissionService>(service);
      addTearDown(
        () => GetIt.I.unregister<NotificationPermissionService>(),
      );

      final schedule = FlightSchedule.dateOnly(
        DateTime.now().add(const Duration(days: 60)),
      );
      await tester.pumpWidget(
        app(stateWith(schedule: schedule), isProUser: true),
      );
      await tester.pump();

      expect(
        find.textContaining('Notifications are off'),
        findsOneWidget,
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump();

      // Granted via the switch: the row disappears.
      expect(service.requested, isTrue);
      expect(find.textContaining('Notifications are off'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    },
  );
}

FlightRoute _route() {
  const departure = Airport(
    name: 'Alpha',
    city: 'A-city',
    countryCode: 'DE',
    latLon: LatLng(50, 0),
    iataCode: 'AAA',
    icaoCode: 'AAAA',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Beta',
    city: 'B-city',
    countryCode: 'ES',
    latLon: LatLng(45, 10),
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

FlightWeather _weather({
  bool isTimeEstimated = false,
  bool rainy = false,
  double arrivalWindMs = 4,
}) {
  AirportWeather airport({double windMs = 4}) => AirportWeather(
    timeUtc: DateTime.utc(2026, 8, 3, 8),
    utcOffsetMinutes: 120,
    temperatureC: 21,
    windSpeedMs: windMs,
    precipitationMm: 0,
    cloudCoverPercent: 10,
    symbolCode: 'clearsky_day',
  );
  return FlightWeather(
    departure: airport(),
    arrival: airport(windMs: arrivalWindMs),
    samples: [
      for (var i = 1; i <= 6; i++)
        RouteCloudSample(
          routeProgress: i / 7,
          latLon: const LatLng(48, 5),
          timeUtc: DateTime.utc(2026, 8, 3, 8 + i),
          cloudLowPercent: 10,
          cloudMidPercent: 0,
          cloudHighPercent: 20,
          precipitationMm: rainy && (i == 3 || i == 4) ? 2.0 : 0,
        ),
    ],
    fetchedAt: DateTime.utc(2026, 7, 28, 9),
    isTimeEstimated: isTimeEstimated,
  );
}

class _FakeNotificationPermissionService
    extends NotificationPermissionService {
  bool granted = false;
  bool requested = false;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async {
    requested = true;
    granted = true;
    return true;
  }
}

class _NoopEncoder implements FlightVideoEncoder {
  @override
  Future<void> setup({
    required int width,
    required int height,
    required int fps,
    required int bitrate,
    required String filePath,
  }) async {}

  @override
  Future<void> appendFrame(Uint8List rawRgba) async {}

  @override
  Future<void> finish() async {}

  @override
  Future<void> abort() async {}
}
