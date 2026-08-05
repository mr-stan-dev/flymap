import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/flight_weather_store.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flight_card.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

class _FakeWeatherStore extends FlightWeatherStore {
  _FakeWeatherStore(this.weather);

  final FlightWeather weather;

  @override
  Future<FlightWeather?> load(String flightId) async => weather;
}

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  tearDown(() async {
    if (GetIt.I.isRegistered<FlightWeatherStore>()) {
      await GetIt.I.unregister<FlightWeatherStore>();
    }
  });

  Future<void> pumpCard(WidgetTester tester, FlightWeather weather) async {
    GetIt.I.registerSingleton<FlightWeatherStore>(_FakeWeatherStore(weather));
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: AppLocale.en.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeFlightCard(
                flight: _flight(),
                distanceUnit: DistanceUnit.km,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a fresh stored weather verdict', (tester) async {
    await pumpCard(tester, _weather(fetchedAt: DateTime.now()));

    expect(find.text('Clear views'), findsOneWidget);
  });

  testWidgets('hides a stored weather verdict after six hours', (tester) async {
    await pumpCard(
      tester,
      _weather(
        fetchedAt: DateTime.now().subtract(FlightWeather.freshnessWindow),
      ),
    );

    expect(find.text('Clear views'), findsNothing);
  });
}

Flight _flight() {
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
    timestamp: FlightTimestamp(createdAt: DateTime(2026, 8, 1)),
    schedule: FlightSchedule(
      travelDate: DateTime.now().add(const Duration(days: 1)),
    ),
  );
}

FlightWeather _weather({required DateTime fetchedAt}) {
  final departure = AirportWeather(
    timeUtc: DateTime(2026, 8, 6, 10),
    utcOffsetMinutes: 60,
  );
  final arrival = AirportWeather(
    timeUtc: DateTime(2026, 8, 6, 13),
    utcOffsetMinutes: 120,
  );
  return FlightWeather(
    departure: departure,
    arrival: arrival,
    samples: [
      RouteCloudSample(
        routeProgress: 0.5,
        latLon: LatLng(48, 6),
        timeUtc: DateTime(2026, 8, 6, 11),
        cloudLowPercent: 5,
        cloudMidPercent: 5,
        cloudHighPercent: 5,
      ),
    ],
    fetchedAt: fetchedAt,
    isTimeEstimated: false,
  );
}
