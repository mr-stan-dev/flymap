import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_flights_by_route_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/flight_search_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/repository/user_flight_prefs_storage.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/viewmodel/airport_selection_screen_state.dart';
import 'package:flymap/ui/screens/create_flight/real_route_airport_search/viewmodel/real_route_airport_search_cubit.dart';
import 'package:flymap/ui/screens/create_flight/real_route_airport_search/viewmodel/real_route_airport_search_state.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('RealRouteAirportSearchCubit', () {
    late _FakeSearchFlightsByRouteUseCase searchUseCase;
    late RealRouteAirportSearchCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding.profile.home_airport_code': 'EGLL',
      });
      searchUseCase = _FakeSearchFlightsByRouteUseCase();
      cubit = RealRouteAirportSearchCubit(
        airportsDb: AirportsDatabase.test(seedAirports: _airports),
        favoritesRepository: FavoriteAirportsRepository(),
        onboardingRepository: OnboardingRepository(
          prefsStorage: UserFlightPrefsStorage(),
        ),
        recentAirportsRepository: RecentAirportsRepository(),
        searchFlightsByRouteUseCase: searchUseCase,
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('initializes with home airport preselected as departure', () {
      expect(cubit.state.airportStep, AirportSelectionStep.departure);
      expect(cubit.state.selectedDeparture?.icaoCode, 'EGLL');
    });

    test('prevents choosing the same airport for arrival', () async {
      await cubit.continueFromAirportStep();
      await cubit.selectAirport(_airports.first);

      expect(cubit.state.selectedArrival, isNull);
    });

    test(
      'loads matched flights after selecting departure and arrival',
      () async {
        final flight = FlightSummary(
          flightNumber: 'BA117',
          fr24Id: 'track-1',
          origIcao: 'EGLL',
          destIcao: 'KJFK',
          departure: _airports.first,
          arrival: _airports[1],
        );
        searchUseCase.flights = <FlightSummary>[flight];

        await cubit.continueFromAirportStep();
        await cubit.selectAirport(_airports[1]);
        await cubit.continueFromAirportStep();

        expect(searchUseCase.lastDepartureCode, 'EGLL');
        expect(searchUseCase.lastArrivalCode, 'KJFK');
        expect(cubit.state.view, RealRouteAirportSearchView.results);
        expect(cubit.state.matchedFlights, hasLength(1));
        expect(cubit.state.selectedMatchedFlight, flight);
      },
    );

    test('preselects the first of multiple matched flights', () async {
      searchUseCase.flights = <FlightSummary>[
        FlightSummary(
          flightNumber: 'BA117',
          origIcao: 'EGLL',
          destIcao: 'KJFK',
          departure: _airports.first,
          arrival: _airports[1],
        ),
        FlightSummary(
          flightNumber: 'VS3',
          origIcao: 'EGLL',
          destIcao: 'KJFK',
          departure: _airports.first,
          arrival: _airports[1],
        ),
      ];

      await cubit.continueFromAirportStep();
      await cubit.selectAirport(_airports[1]);
      await cubit.continueFromAirportStep();

      expect(cubit.state.matchedFlights, hasLength(2));
      expect(
        cubit.state.selectedMatchedFlight,
        cubit.state.matchedFlights.first,
      );
    });

    test('maps not-found failures to empty-results copy', () async {
      searchUseCase.error = FirebaseFunctionsException(
        code: 'not-found',
        message: 'not found',
      );

      await cubit.continueFromAirportStep();
      await cubit.selectAirport(_airports[1]);
      await cubit.continueFromAirportStep();

      expect(
        cubit.state.routeSearchErrorMessage,
        'Make sure you selected the same departure and arrival airports as on your flight ticket.',
      );
    });

    test('maps unavailable failures to provider copy', () async {
      searchUseCase.error = FirebaseFunctionsException(
        code: 'unavailable',
        message: 'later',
      );

      await cubit.continueFromAirportStep();
      await cubit.selectAirport(_airports[1]);
      await cubit.continueFromAirportStep();

      expect(
        cubit.state.routeSearchErrorMessage,
        'Real-flight data is temporarily unavailable. Please try again in a moment.',
      );
    });

    test('maps resource-exhausted failures to retry-later copy', () async {
      searchUseCase.error = FirebaseFunctionsException(
        code: 'resource-exhausted',
        message: 'Too many requests',
      );

      await cubit.continueFromAirportStep();
      await cubit.selectAirport(_airports[1]);
      await cubit.continueFromAirportStep();

      expect(
        cubit.state.routeSearchErrorMessage,
        'Too many flight searches right now. Please try again in a moment.',
      );
    });

    test(
      'back from results returns to arrival step with airports preserved',
      () async {
        searchUseCase.flights = <FlightSummary>[
          FlightSummary(
            flightNumber: 'BA117',
            origIcao: 'EGLL',
            destIcao: 'KJFK',
            departure: _airports.first,
            arrival: _airports[1],
          ),
        ];

        await cubit.continueFromAirportStep();
        await cubit.selectAirport(_airports[1]);
        await cubit.continueFromAirportStep();

        final shouldPop = await cubit.handleBackAction();

        expect(shouldPop, isFalse);
        expect(cubit.state.view, RealRouteAirportSearchView.airportSelection);
        expect(cubit.state.airportStep, AirportSelectionStep.arrival);
        expect(cubit.state.selectedDeparture?.icaoCode, 'EGLL');
        expect(cubit.state.selectedArrival?.icaoCode, 'KJFK');
      },
    );

  });
}

class _FakeSearchFlightsByRouteUseCase extends SearchFlightsByRouteUseCase {
  _FakeSearchFlightsByRouteUseCase()
    : super(repository: _UnusedFlightSearchRepository());

  List<FlightSummary> flights = const <FlightSummary>[];
  Object? error;
  String? lastDepartureCode;
  String? lastArrivalCode;

  @override
  Future<List<FlightSummary>> call({
    required String departureCode,
    required String arrivalCode,
  }) async {
    lastDepartureCode = departureCode;
    lastArrivalCode = arrivalCode;
    if (error != null) throw error!;
    return flights;
  }
}

class _UnusedFlightSearchRepository implements FlightSearchRepository {
  @override
  Future<Map<String, dynamic>> buildFlightRoutePreview({
    required String flightNumber,
    String? fr24Id,
    String? origCode,
    String? destCode,
    required int placesLimit,
    required int regionsLimit,
    String lang = 'en',
  }) {
    throw UnimplementedError();
  }


  @override
  Future<List<FlightSummary>> searchFlightsByNumber(String flightNumber) {
    throw UnimplementedError();
  }

  @override
  Future<List<FlightSummary>> searchUpcomingFlightsByNumber(
    String flightNumber, {
    DateTime? date,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Airport> resolveAirport({
    LatLng? latLon,
    required String? code,
    required String fallbackName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String?> resolveAirlineNameByCode(String? code) {
    throw UnimplementedError();
  }

  @override
  Future<List<FlightSummary>> searchFlightsByRoute({
    required String departureCode,
    required String arrivalCode,
  }) {
    throw UnimplementedError();
  }
}

const List<Airport> _airports = <Airport>[
  Airport(
    name: 'Heathrow Airport',
    city: 'London',
    countryCode: 'GB',
    latLon: LatLng(51.47, -0.4543),
    iataCode: 'LHR',
    icaoCode: 'EGLL',
    wikipediaUrl: '',
  ),
  Airport(
    name: 'John F. Kennedy International Airport',
    city: 'New York',
    countryCode: 'US',
    latLon: LatLng(40.6413, -73.7781),
    iataCode: 'JFK',
    icaoCode: 'KJFK',
    wikipediaUrl: '',
  ),
];
