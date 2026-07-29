import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/flight_search_weather_step.dart';
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
    expect(find.textContaining('Forecast for'), findsOneWidget);
    // Airport cards sit at the top, before the map.
    expect(find.textContaining('AAA'), findsOneWidget);
    expect(find.textContaining('BBB'), findsOneWidget);
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

  testWidgets('date-only flights never display the internal noon estimate', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(stateWith(weather: _weather(isTimeEstimated: true))),
    );

    expect(tester.takeException(), isNull);
    // 10:00 local = the noon-ish estimate; the clock must not be shown.
    expect(find.textContaining('10:00'), findsNothing);
    expect(find.textContaining('(tomorrow)'), findsNothing);
    // The badge explains what the forecast represents instead.
    expect(find.textContaining('daytime forecast'), findsOneWidget);
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

FlightWeather _weather({bool isTimeEstimated = false}) {
  AirportWeather airport() => AirportWeather(
    timeUtc: DateTime.utc(2026, 8, 3, 8),
    utcOffsetMinutes: 120,
    temperatureC: 21,
    windSpeedMs: 4,
    precipitationMm: 0,
    cloudCoverPercent: 10,
    symbolCode: 'clearsky_day',
  );
  return FlightWeather(
    departure: airport(),
    arrival: airport(),
    samples: [
      for (var i = 1; i <= 6; i++)
        RouteCloudSample(
          routeProgress: i / 7,
          latLon: const LatLng(48, 5),
          timeUtc: DateTime.utc(2026, 8, 3, 8 + i),
          cloudLowPercent: 10,
          cloudMidPercent: 0,
          cloudHighPercent: 20,
        ),
    ],
    fetchedAt: DateTime.utc(2026, 7, 28, 9),
    isTimeEstimated: isTimeEstimated,
  );
}
