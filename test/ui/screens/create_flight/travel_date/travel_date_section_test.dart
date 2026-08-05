import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';
import 'package:flymap/domain/usecase/search_upcoming_flights_by_number_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/flight_number_search/widgets/flight_summary_card.dart';
import 'package:flymap/ui/screens/create_flight/travel_date/travel_date_section.dart';
import 'package:flymap/ui/screens/create_flight/widgets/compact_flight_strip.dart';
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

/// Serves one departure (16:10 local) for any exact-date verification.
class _FakeUpcomingUseCase implements SearchUpcomingFlightsByNumberUseCase {
  final requestedDates = <DateTime>[];

  /// When false, exact-date verification finds nothing.
  bool servesRequestedDate = true;

  /// When true, the entry mimics a departure-only schedule row (BA117
  /// style): no arrival block, schedule-feed aircraft.
  bool servesSparseEntry = false;

  @override
  Future<List<FlightSummary>> call(
    String flightNumber, {
    DateTime? date,
  }) async {
    if (date == null) return const [];
    requestedDates.add(date);
    // Small real-ish latency so tests can observe the loading state.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!servesRequestedDate) return const [];
    return [
      FlightSummary(
        flightNumber: 'FR6221',
        fr24Id: null,
        origIcao: 'EGGD',
        destIcao: servesSparseEntry ? null : 'EPKK',
        airlineCode: 'FR',
        airlineName: 'Ryanair',
        historicalFlightDate: null,
        aircraftType: servesSparseEntry ? 'Airbus A320' : null,
        departure: _departure,
        arrival: servesSparseEntry ? null : _arrival,
        travelDateLocal: DateTime(date.year, date.month, date.day),
        scheduledDeparture: ZonedInstant(
          utc: DateTime.utc(date.year, date.month, date.day, 15, 10),
          offsetMinutes: 60,
        ),
      ),
    ];
  }
}

Widget _app({
  FlightSummary? confirmedFlight,
  ValueChanged<TravelDateSelection?>? onSelectionChanged,
}) {
  return TranslationProvider(
    child: MaterialApp(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: ListView(
          children: [
            TravelDateSection(
              departure: _departure,
              arrival: _arrival,
              flightNumber: 'FR6221',
              confirmedFlight: confirmedFlight,
              onSelectionChanged: onSelectionChanged ?? (_) {},
              onBusyChanged: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('idle shows the three quick options only', (tester) async {
    await tester.pumpWidget(_app());

    expect(tester.takeException(), isNull);
    expect(find.text('When are you flying?'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Pick another date'), findsOneWidget);
    expect(find.byType(FlightSummaryCard), findsNothing);
  });

  testWidgets('picked date is verified and reveals the full flight card', (
    tester,
  ) async {
    final useCase = _FakeUpcomingUseCase();
    GetIt.I.registerSingleton<SearchUpcomingFlightsByNumberUseCase>(useCase);
    addTearDown(
      () => GetIt.I.unregister<SearchUpcomingFlightsByNumberUseCase>(),
    );
    TravelDateSelection? selection;

    final confirmed = FlightSummary(
      flightNumber: 'FR6221',
      fr24Id: 'recorded-leg',
      origIcao: 'EGGD',
      destIcao: 'EPKK',
      airlineCode: 'FR',
      airlineName: 'Ryanair',
      historicalFlightDate: null,
      departure: _departure,
      arrival: _arrival,
    );
    await tester.pumpWidget(
      _app(
        confirmedFlight: confirmed,
        onSelectionChanged: (value) => selection = value,
      ),
    );

    // Idle: identity strip + the date question.
    expect(find.byType(CompactFlightStrip), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    // While verifying, the strip hides — loading only.
    expect(find.byType(CompactFlightStrip), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    // The strip is REPLACED by the full card; Change date sits below it.
    expect(useCase.requestedDates, hasLength(1));
    expect(find.text('Tomorrow'), findsNothing);
    expect(find.byType(CompactFlightStrip), findsNothing);
    expect(find.byType(FlightSummaryCard), findsOneWidget);
    expect(find.text('Change date'), findsOneWidget);
    expect(find.textContaining('16:10'), findsWidgets);
    // The verified schedule was reported to the host screen.
    expect(selection?.schedule?.departure, isNotNull);
  });

  testWidgets(
    'sparse verify entry cannot degrade the confirmed flight identity',
    (tester) async {
      final useCase = _FakeUpcomingUseCase()..servesSparseEntry = true;
      GetIt.I.registerSingleton<SearchUpcomingFlightsByNumberUseCase>(useCase);
      addTearDown(
        () => GetIt.I.unregister<SearchUpcomingFlightsByNumberUseCase>(),
      );

      final confirmed = FlightSummary(
        flightNumber: 'FR6221',
        fr24Id: 'recorded-leg',
        origIcao: 'EGGD',
        destIcao: 'EPKK',
        airlineCode: 'FR',
        airlineName: 'Ryanair',
        historicalFlightDate: null,
        aircraftType: 'Boeing 737-800',
        actualDistanceKm: 1710,
        actualDurationMinutes: 145,
        departure: _departure,
        arrival: _arrival,
      );

      await tester.pumpWidget(_app(confirmedFlight: confirmed));

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Identity from the confirmed card, schedule from the verification.
      expect(find.textContaining('KRK'), findsWidgets);
      expect(find.textContaining('Boeing 737-800'), findsOneWidget);
      expect(find.textContaining('Airbus A320'), findsNothing);
      expect(find.textContaining('16:10'), findsWidgets);
    },
  );

  testWidgets('miss shows the honest panel and change date returns to idle', (
    tester,
  ) async {
    final useCase = _FakeUpcomingUseCase()..servesRequestedDate = false;
    GetIt.I.registerSingleton<SearchUpcomingFlightsByNumberUseCase>(useCase);
    addTearDown(
      () => GetIt.I.unregister<SearchUpcomingFlightsByNumberUseCase>(),
    );
    TravelDateSelection? selection;

    await tester.pumpWidget(
      _app(onSelectionChanged: (value) => selection = value),
    );

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("couldn't find this flight on this date"),
      findsOneWidget,
    );
    expect(find.byType(FlightSummaryCard), findsNothing);
    expect(find.text('Change date'), findsOneWidget);
    // A provider miss leaves the date incomplete until a precise manual time
    // is entered; it must never become a silent noon schedule.
    expect(selection, isNull);

    await tester.tap(find.text('Change date'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(selection, isNull);
  });

  testWidgets('dateless is an explicit chip choice, never a default', (
    tester,
  ) async {
    TravelDateSelection? selection;
    var callbackFired = false;

    await tester.pumpWidget(
      _app(
        onSelectionChanged: (value) {
          callbackFired = true;
          selection = value;
        },
      ),
    );

    // Nothing selected by default.
    expect(callbackFired, isFalse);
    expect(find.text('No date yet'), findsOneWidget);

    await tester.tap(find.text('No date yet'));
    await tester.pumpAndSettle();

    // Explicit dateless: reported with a null schedule, chip confirmed,
    // change-date way back available.
    expect(callbackFired, isTrue);
    expect(selection, isNotNull);
    expect(selection!.schedule, isNull);
    expect(find.text('Today'), findsNothing);
    expect(find.text('Change date'), findsOneWidget);

    await tester.tap(find.text('Change date'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(selection, isNull);
  });

  testWidgets(
    'manual date requires a precise time when the airport timezone is known',
    (tester) async {
      GetIt.I.registerSingleton<AirportTimezoneService>(
        AirportTimezoneService(
          airportsDatabase: AirportsDatabase.test(
            seedTimezones: {'EGGD': 'Europe/London'},
          ),
        ),
      );
      addTearDown(() => GetIt.I.unregister<AirportTimezoneService>());
      TravelDateSelection? selection;

      await tester.pumpWidget(
        _app(onSelectionChanged: (value) => selection = value),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // No verify DI: the calendar date alone is not a valid selection.
      expect(selection, isNull);
      expect(find.text('Add departure time'), findsOneWidget);
      await tester.tap(find.text('Add departure time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Departure time ·'), findsOneWidget);
      expect(selection?.schedule?.departure, isNull);
      expect(
        selection?.schedule?.timePrecision,
        FlightScheduleTimePrecision.approximateTime,
      );
      expect(selection?.schedule?.approximateDepartureTime?.hour, 12);
    },
  );
}
