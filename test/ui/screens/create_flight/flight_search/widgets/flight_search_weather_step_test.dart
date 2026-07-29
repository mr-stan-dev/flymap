import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/data/flight_video/video_encoder.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_service.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
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

  FlightPreviewState stateWith({FlightWeather? weather, bool loading = false}) {
    return FlightPreviewState.initial().copyWith(
      step: CreateFlightStep.weather,
      flightRoute: _route(),
      flightWeather: weather,
      isWeatherLoading: loading,
    );
  }

  Widget app(FlightPreviewState state, {bool isProUser = false}) {
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
          ),
        ),
      ),
    );
  }

  testWidgets('renders airport cards, verdict and teaser for free users', (
    tester,
  ) async {
    await tester.pumpWidget(app(stateWith(weather: _weather())));

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
    // The portrait map card pushes the rest below the fold — scroll in
    // layout order.
    await tester.scrollUntilVisible(find.text('Upgrade to Pro'), 200);
    expect(find.text('Upgrade to Pro'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Clear views'), 200);
    expect(find.text('Clear views'), findsOneWidget);
  });

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
      app(stateWith(weather: _weather(isTimeEstimated: true))),
    );

    expect(tester.takeException(), isNull);
    // 10:00 local = the noon-ish estimate; the clock must not be shown.
    expect(find.textContaining('10:00', findRichText: true), findsNothing);
    expect(find.textContaining('(tomorrow)'), findsNothing);
  });

  testWidgets('verdict card lists only wind warnings, no region breakdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(stateWith(weather: _weather(rainy: true, arrivalWindMs: 12))),
    );

    // The per-region cloud/rain rows are gone — they read as contradictions
    // on real forecasts. Only the landing wind warning remains.
    await tester.scrollUntilVisible(
      find.textContaining('Windy landing'),
      200,
    );
    expect(find.textContaining('Windy landing in B-city'), findsOneWidget);
    expect(find.textContaining('Rain mid-flight'), findsNothing);
    expect(find.textContaining('after takeoff'), findsNothing);
  });

  testWidgets('calm flights show the verdict sentence, no list', (
    tester,
  ) async {
    await tester.pumpWidget(app(stateWith(weather: _weather())));

    await tester.scrollUntilVisible(find.text('Clear views'), 200);
    // The verdict body sentence is the whole story when nothing is notable.
    expect(find.textContaining('Window seat worth it'), findsOneWidget);
    expect(find.textContaining('Windy'), findsNothing);
  });

  testWidgets('failed load shows retry and keeps Continue', (tester) async {
    await tester.pumpWidget(app(stateWith()));

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
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
