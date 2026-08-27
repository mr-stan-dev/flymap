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
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_route_map_card.dart';
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
    FlightRoute? route,
  }) {
    return FlightPreviewState.initial().copyWith(
      step: CreateFlightStep.weather,
      flightRoute: route ?? _route(),
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
    TextScaler? textScaler,
  }) {
    return TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: textScaler == null
            ? null
            : (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                child: child!,
              ),
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

  testWidgets('renders airport cards and times for Pro users', (tester) async {
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
    expect(find.textContaining('GMT+2', findRichText: true), findsNWidgets(2));
    // Wind remains visible in the compact overview; its strength label is
    // retained in semantics while the card shows the concise measurement.
    expect(find.text('4 m/s'), findsNWidgets(2));
    // The compact verdict answers the headline without a second sentence.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('weather-verdict-chip')),
      250,
    );
    await tester.pump();
    expect(find.text('Clear views'), findsOneWidget);
    expect(find.byKey(const ValueKey('weather-verdict-chip')), findsOneWidget);
    expect(find.textContaining('Window seat worth it'), findsNothing);
  });

  testWidgets('uses airport, place, and date hierarchy in full-width cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final route = _route(
      arrivalCode: 'FCO',
      arrivalCity: 'Rome',
      arrivalCountryCode: 'IT',
    );

    await tester.pumpWidget(
      app(
        stateWith(
          route: route,
          weather: _weather(
            isTimeEstimated: true,
            departureOffsetMinutes: 60,
            arrivalOffsetMinutes: 120,
            arrivalTimeUtc: DateTime.utc(2026, 8, 4, 1, 13),
          ),
        ),
        isProUser: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('airport-weather-cards-column')),
      findsOneWidget,
    );
    final code = tester.widget<Text>(find.text('FCO'));
    expect(code.maxLines, 1);
    expect(code.softWrap, isFalse);
    expect(find.text('Rome · IT'), findsOneWidget);
    final codeCenter = tester.getCenter(find.text('FCO'));
    final placeCenter = tester.getCenter(find.text('Rome · IT'));
    expect(placeCenter.dy, closeTo(codeCenter.dy, 1));
    expect(find.textContaining('GMT+2 ·'), findsOneWidget);
    final departureBottom = tester.getBottomLeft(
      find.byKey(const ValueKey('departure-airport-weather-card')),
    );
    final arrivalTop = tester.getTopLeft(
      find.byKey(const ValueKey('arrival-airport-weather-card')),
    );
    expect(arrivalTop.dy, greaterThan(departureBottom.dy));
  });

  testWidgets('keeps full-width cards compact on small phone screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final longCity = 'A very long airport city name that must never squeeze';
    await tester.pumpWidget(
      app(
        stateWith(
          route: _route(arrivalCity: longCity),
          weather: _weather(),
        ),
        isProUser: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('airport-weather-cards-column')),
      findsOneWidget,
    );
    final departureCard = find.byKey(
      const ValueKey('departure-airport-weather-card'),
    );
    final departureBottom = tester.getBottomLeft(departureCard);
    final arrivalTop = tester.getTopLeft(
      find.byKey(const ValueKey('arrival-airport-weather-card')),
    );
    expect(arrivalTop.dy, greaterThan(departureBottom.dy));
    final cardSize = tester.getSize(departureCard);
    expect(cardSize.width, greaterThan(280));
    expect(cardSize.height, lessThan(80));
    final cityText = tester.widget<Text>(find.text('$longCity · ES'));
    expect(cityText.maxLines, 1);
    expect(cityText.overflow, TextOverflow.ellipsis);
    // The fixed weather summary remains visible beside the truncated place.
    expect(
      find.byKey(const ValueKey('airport-weather-icon-clearDay')),
      findsNWidgets(2),
    );
  });

  testWidgets(
    'expands to normal local clock slots with the flight at its exact time',
    (tester) async {
      await tester.pumpWidget(
        app(stateWith(weather: _weather()), isProUser: true),
      );
      await tester.pump();

      expect(find.byIcon(Icons.flight_takeoff_rounded), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('airport-weather-expansion-AAA')),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flight_land_rounded), findsNothing);
      for (final time in [
        '03:00',
        '06:00',
        '09:00',
        '12:00',
        '15:00',
        '18:00',
      ]) {
        expect(find.text(time), findsOneWidget);
      }
      // The scheduled departure remains 10:00 and its marker sits between
      // the surrounding 09:00 and 12:00 forecast slots.
      expect(
        find.textContaining('10:00', findRichText: true),
        findsNWidgets(2),
      );
      final markerCenter = tester.getCenter(
        find.byKey(const ValueKey('airport-weather-event-marker-departure')),
      );
      final markerBottom = tester.getBottomLeft(
        find.byKey(const ValueKey('airport-weather-event-marker-departure')),
      );
      final connectorTop = tester.getTopLeft(
        find.byKey(const ValueKey('airport-weather-event-connector-departure')),
      );
      final eventDotCenter = tester.getCenter(
        find.byKey(const ValueKey('airport-weather-event-dot-departure')),
      );
      expect(
        markerCenter.dx,
        greaterThan(tester.getCenter(find.text('09:00')).dx),
      );
      expect(
        markerCenter.dx,
        lessThan(tester.getCenter(find.text('12:00')).dx),
      );
      expect(connectorTop.dy, closeTo(markerBottom.dy, 0.1));
      expect(eventDotCenter.dy, greaterThan(markerCenter.dy));
    },
  );

  testWidgets('uses consistent SVG icons and light-rain presentation', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        stateWith(
          weather: _weather(
            departureSymbolCode: 'cloudy',
            arrivalSymbolCode: 'rain',
            arrivalPrecipitationMm: 0.2,
          ),
        ),
        isProUser: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('airport-weather-icon-cloudy')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('airport-weather-icon-lightRainDay')),
      findsOneWidget,
    );
    expect(find.text('☁️'), findsNothing);
    expect(find.text('🌧️'), findsNothing);
    expect(find.text('0.2 mm/h'), findsOneWidget);
    final windText = tester.widgetList<Text>(find.text('4 m/s')).first;
    final precipitationText = tester.widget<Text>(find.text('0.2 mm/h'));
    expect(windText.style?.fontSize, precipitationText.style?.fontSize);
  });

  testWidgets('derives airport day and night icons from time and position', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        stateWith(
          weather: _weather(
            departureTimeUtc: DateTime.utc(2026, 8, 3, 12),
            arrivalTimeUtc: DateTime.utc(2026, 8, 3),
            // Deliberately contradictory provider suffixes: solar position
            // must be authoritative for presentation.
            departureSymbolCode: 'clearsky_night',
            arrivalSymbolCode: 'clearsky_day',
          ),
        ),
        isProUser: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('airport-weather-icon-clearDay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('airport-weather-icon-clearNight')),
      findsOneWidget,
    );
  });

  testWidgets('stacks airport cards for accessibility text sizes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      app(
        stateWith(weather: _weather()),
        isProUser: true,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('airport-weather-cards-column')),
      findsOneWidget,
    );
    expect(find.text('AAA'), findsOneWidget);
    expect(find.text('BBB'), findsOneWidget);
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

  testWidgets('a refreshed forecast remounts the cloud animation', (
    tester,
  ) async {
    final first = _weather(fetchedAt: DateTime.utc(2026, 8, 1, 10));
    final refreshed = _weather(fetchedAt: DateTime.utc(2026, 8, 1, 11));

    await tester.pumpWidget(app(stateWith(weather: first), isProUser: true));
    final firstCard = tester.widget<WeatherRouteMapCard>(
      find.byType(WeatherRouteMapCard),
    );

    await tester.pumpWidget(
      app(stateWith(weather: refreshed), isProUser: true),
    );
    final refreshedCard = tester.widget<WeatherRouteMapCard>(
      find.byType(WeatherRouteMapCard),
    );

    expect(firstCard.key, ObjectKey(first));
    expect(refreshedCard.key, ObjectKey(refreshed));
    expect(refreshedCard.key, isNot(firstCard.key));
  });

  testWidgets('does not render the obsolete route outlook card', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        stateWith(weather: _weather(rainy: true, arrivalWindMs: 9)),
        isProUser: true,
      ),
    );

    expect(find.text('Along the route'), findsNothing);
    expect(find.text('Rain possible around the middle'), findsNothing);
    expect(find.textContaining('Windy landing in B-city'), findsNothing);
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
                WeatherShareButton(route: _route(), weather: _weather()),
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

  testWidgets('estimated forecasts show plain airport times', (tester) async {
    await tester.pumpWidget(
      app(stateWith(weather: _weather(isTimeEstimated: true)), isProUser: true),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Times are estimated'), findsNothing);
    expect(find.textContaining('~10:00', findRichText: true), findsNothing);
    expect(find.textContaining('10:00', findRichText: true), findsNWidgets(2));
  });

  testWidgets('legacy period schedules do not restore the removed banner', (
    tester,
  ) async {
    final schedule = FlightSchedule.approximate(
      DateTime(2026, 8, 4),
      departureTime: const ApproximateDepartureTime(
        hour: 23,
        minute: 0,
        period: ApproximateDeparturePeriod.night,
      ),
    );

    await tester.pumpWidget(
      app(
        stateWith(schedule: schedule, weather: _weather(isTimeEstimated: true)),
        isProUser: true,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Times use an approximate'), findsNothing);
  });

  testWidgets('past flight explains why retry is unavailable', (tester) async {
    final schedule = _manualSchedule(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      app(stateWith(schedule: schedule), isProUser: true),
    );

    expect(find.text('This flight date has passed'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('failed load shows retry and keeps Continue for Pro', (
    tester,
  ) async {
    // A failed load implies a date was set (the fetch is gated on one);
    // without a date the step shows the "pick a date" prompt instead.
    final schedule = _manualSchedule(
      DateTime.now().add(const Duration(days: 2)),
    );
    await tester.pumpWidget(
      app(stateWith(schedule: schedule), isProUser: true),
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('dateless approximate flight prompts for date and time', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(stateWith(), isProUser: true, onPickDate: () {}),
    );

    expect(find.text('Pick date & time'), findsOneWidget);
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
    expect(find.text('Pick date & time'), findsNothing);
    expect(find.text('Go back to pick a date'), findsOneWidget);

    await tester.tap(find.text('Go back to pick a date'));
    expect(wentBack, isTrue);
  });

  testWidgets(
    'far-future flights explain the forecast horizon instead of failing',
    (tester) async {
      final schedule = _manualSchedule(
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
      addTearDown(() => GetIt.I.unregister<NotificationPermissionService>());

      final schedule = _manualSchedule(
        DateTime.now().add(const Duration(days: 60)),
      );
      await tester.pumpWidget(
        app(stateWith(schedule: schedule), isProUser: true),
      );
      await tester.pump();

      expect(find.textContaining('Notifications are off'), findsOneWidget);

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

FlightSchedule _manualSchedule(DateTime date) {
  return FlightSchedule.approximate(
    date,
    departureTime: const ApproximateDepartureTime(hour: 12, minute: 0),
  );
}

FlightRoute _route({
  String arrivalCode = 'BBB',
  String arrivalCity = 'B-city',
  String arrivalCountryCode = 'ES',
}) {
  const departure = Airport(
    name: 'Alpha',
    city: 'A-city',
    countryCode: 'DE',
    latLon: LatLng(50, 0),
    iataCode: 'AAA',
    icaoCode: 'AAAA',
    wikipediaUrl: '',
  );
  final arrival = Airport(
    name: 'Beta',
    city: arrivalCity,
    countryCode: arrivalCountryCode,
    latLon: const LatLng(45, 10),
    iataCode: arrivalCode,
    icaoCode: 'BBBB',
    wikipediaUrl: '',
  );
  return FlightRoute(
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
  List<double>? lowCloudPercent,
  int departureOffsetMinutes = 120,
  int arrivalOffsetMinutes = 120,
  DateTime? departureTimeUtc,
  DateTime? arrivalTimeUtc,
  DateTime? fetchedAt,
  String departureSymbolCode = 'clearsky_day',
  String arrivalSymbolCode = 'clearsky_day',
  double departurePrecipitationMm = 0,
  double arrivalPrecipitationMm = 0,
  bool withAirportTimeline = true,
}) {
  AirportWeather airport({
    double windMs = 4,
    int offsetMinutes = 120,
    DateTime? timeUtc,
    required String symbolCode,
    required double precipitationMm,
  }) {
    final eventTimeUtc = timeUtc ?? DateTime.utc(2026, 8, 3, 8);
    return AirportWeather(
      timeUtc: eventTimeUtc,
      utcOffsetMinutes: offsetMinutes,
      temperatureC: 21,
      windSpeedMs: windMs,
      precipitationMm: precipitationMm,
      cloudCoverPercent: 10,
      symbolCode: symbolCode,
      timeline: withAirportTimeline
          ? _airportTimeline(
              eventTimeUtc: eventTimeUtc,
              offsetMinutes: offsetMinutes,
              windMs: windMs,
              symbolCode: symbolCode,
              precipitationMm: precipitationMm,
            )
          : const [],
    );
  }

  return FlightWeather(
    departure: airport(
      offsetMinutes: departureOffsetMinutes,
      timeUtc: departureTimeUtc,
      symbolCode: departureSymbolCode,
      precipitationMm: departurePrecipitationMm,
    ),
    arrival: airport(
      windMs: arrivalWindMs,
      offsetMinutes: arrivalOffsetMinutes,
      timeUtc: arrivalTimeUtc,
      symbolCode: arrivalSymbolCode,
      precipitationMm: arrivalPrecipitationMm,
    ),
    samples: [
      for (var i = 1; i <= 6; i++)
        RouteCloudSample(
          routeProgress: i / 7,
          latLon: const LatLng(48, 5),
          timeUtc: DateTime.utc(2026, 8, 3, 8 + i),
          cloudLowPercent: lowCloudPercent?[i - 1] ?? 10,
          cloudMidPercent: 0,
          cloudHighPercent: 20,
          precipitationMm: rainy && (i == 3 || i == 4) ? 2.0 : 0,
        ),
    ],
    fetchedAt: fetchedAt ?? DateTime.utc(2026, 7, 28, 9),
    isTimeEstimated: isTimeEstimated,
  );
}

List<AirportForecastSlice> _airportTimeline({
  required DateTime eventTimeUtc,
  required int offsetMinutes,
  required double windMs,
  required String symbolCode,
  required double precipitationMm,
}) {
  final eventLocal = eventTimeUtc.add(Duration(minutes: offsetMinutes));
  final midnight = DateTime.utc(
    eventLocal.year,
    eventLocal.month,
    eventLocal.day,
  );
  final startMinutes = eventLocal
      .subtract(const Duration(hours: 6))
      .difference(midnight)
      .inMinutes;
  final endMinutes = eventLocal
      .add(const Duration(hours: 6))
      .difference(midnight)
      .inMinutes;
  final firstSlot = (startMinutes / 180).floor() * 180;
  final lastSlot = (endMinutes / 180).ceil() * 180;
  return [
    for (var minutes = firstSlot; minutes <= lastSlot; minutes += 180)
      AirportForecastSlice(
        timeUtc: midnight
            .add(Duration(minutes: minutes))
            .subtract(Duration(minutes: offsetMinutes)),
        temperatureC: 21,
        windSpeedMs: windMs,
        precipitationMm: precipitationMm,
        cloudCoverPercent: 10,
        symbolCode: symbolCode,
      ),
  ];
}

class _FakeNotificationPermissionService extends NotificationPermissionService {
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
