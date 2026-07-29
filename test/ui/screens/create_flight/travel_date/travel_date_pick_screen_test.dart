import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';
import 'package:flymap/domain/usecase/search_upcoming_flights_by_number_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/travel_date/travel_date_pick_screen.dart';
import 'package:get_it/get_it.dart';
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

/// Serves one departure (16:10 local) for any exact-date verification.
class _FakeUpcomingUseCase implements SearchUpcomingFlightsByNumberUseCase {
  final requestedDates = <DateTime>[];

  /// When false, exact-date verification finds nothing.
  bool servesRequestedDate = true;

  @override
  Future<List<FlightSummary>> call(String flightNumber, {DateTime? date}) async {
    if (date == null) return const [];
    requestedDates.add(date);
    if (!servesRequestedDate) return const [];
    return [
      FlightSummary(
        flightNumber: 'FR6221',
        fr24Id: null,
        origIcao: 'EGGD',
        destIcao: 'EPKK',
        airlineCode: 'FR',
        airlineName: 'Ryanair',
        historicalFlightDate: null,
        travelDateLocal: DateTime(date.year, date.month, date.day),
        scheduledDeparture: ZonedInstant(
          utc: DateTime.utc(date.year, date.month, date.day, 15, 10),
          offsetMinutes: 60,
        ),
      ),
    ];
  }
}

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('approximate flight shows all 7 days plus custom date at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const TravelDatePickArgs(departure: _departure, arrival: _arrival)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    // All seven days render as a compact grid, custom-date row below.
    expect(find.byIcon(Icons.event_rounded), findsNWidgets(7));
    expect(find.byType(GridView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pick another date'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pick another date'), findsOneWidget);
  });

  testWidgets(
    'real flight shows only pick-a-date and the dateless hatch — no lists',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const TravelDatePickArgs(
            departure: _departure,
            arrival: _arrival,
            flightNumber: 'FR6221',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // Quick picks + calendar + the dateless hatch — nothing else.
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Pick your travel date'), findsOneWidget);
      expect(find.text('Continue without a date'), findsOneWidget);
      // No browsing UI: no day grid, no dated schedule rows.
      expect(find.byType(GridView), findsNothing);
    },
  );

  testWidgets('picked date is verified and gets the real departure time', (
    tester,
  ) async {
    final useCase = _FakeUpcomingUseCase();
    GetIt.I.registerSingleton<SearchUpcomingFlightsByNumberUseCase>(useCase);
    addTearDown(
      () => GetIt.I.unregister<SearchUpcomingFlightsByNumberUseCase>(),
    );

    await tester.pumpWidget(
      _app(
        const TravelDatePickArgs(
          departure: _departure,
          arrival: _arrival,
          flightNumber: 'FR6221',
        ),
      ),
    );

    // One tap on the Today quick row verifies that date directly.
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(useCase.requestedDates, hasLength(1));
    expect(find.textContaining('16:10'), findsOneWidget);
    expect(find.textContaining('find this flight'), findsNothing);
    // Verified: no manual time entry offered.
    expect(find.textContaining('departure time'), findsNothing);
  });

  testWidgets('picked date without a departure stays honest date-only', (
    tester,
  ) async {
    final useCase = _FakeUpcomingUseCase()..servesRequestedDate = false;
    GetIt.I.registerSingleton<SearchUpcomingFlightsByNumberUseCase>(useCase);
    addTearDown(
      () => GetIt.I.unregister<SearchUpcomingFlightsByNumberUseCase>(),
    );

    await tester.pumpWidget(
      _app(
        const TravelDatePickArgs(
          departure: _departure,
          arrival: _arrival,
          flightNumber: 'FR6221',
        ),
      ),
    );

    await tester.tap(find.text('Pick your travel date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Prominent, honest miss message with an edit-the-date pointer.
    expect(
      find.textContaining("couldn't find this flight on this date"),
      findsOneWidget,
    );
    expect(find.textContaining('tap it to change'), findsOneWidget);
    expect(find.textContaining('16:10'), findsNothing);
  });

  testWidgets(
    'manual date offers optional time when the airport timezone is known',
    (tester) async {
      GetIt.I.registerSingleton<AirportTimezoneService>(
        AirportTimezoneService(
          airportsDatabase: AirportsDatabase.test(
            seedTimezones: {'EGGD': 'Europe/London'},
          ),
        ),
      );
      addTearDown(() => GetIt.I.unregister<AirportTimezoneService>());

      await tester.pumpWidget(
        _app(
          const TravelDatePickArgs(
            departure: _departure,
            arrival: _arrival,
            flightNumber: 'FR6221',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No time row until a date is picked.
      expect(find.textContaining('departure time'), findsNothing);

      await tester.tap(find.text('Pick your travel date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Add departure time (optional)'), findsOneWidget);
      await tester.tap(find.text('Add departure time (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Departure time ·'), findsOneWidget);
    },
  );
}
