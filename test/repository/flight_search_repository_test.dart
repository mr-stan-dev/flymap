import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/flight_lookup_api.dart';
import 'package:flymap/data/api/flight_number_search_api.dart';
import 'package:flymap/data/api/flight_route_preview_api.dart';
import 'package:flymap/data/api/flight_route_search_api.dart';
import 'package:flymap/data/api/upcoming_flight_search_api.dart';
import 'package:flymap/data/local/airlines_database.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/repository/flight_search_repository.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('ApiFlightSearchRepository searchFlightsByRoute', () {
    late _FakeFlightRouteSearchApi routeSearchApi;
    late ApiFlightSearchRepository repository;

    setUp(() {
      routeSearchApi = _FakeFlightRouteSearchApi();
      repository = ApiFlightSearchRepository(
        lookupApi: _FakeFlightLookupApi(),
        numberSearchApi: _FakeFlightNumberSearchApi(),
        upcomingSearchApi: _FakeUpcomingFlightSearchApi(),
        routeSearchApi: routeSearchApi,
        routePreviewApi: _FakeFlightRoutePreviewApi(),
        airportsDb: AirportsDatabase.test(
          seedAirports: const <Airport>[
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
          ],
        ),
        airlinesDb: AirlinesDatabase.test(
          seedAirlines: const <Airline>[
            Airline(name: 'British Airways', iataCode: 'BA', icaoCode: 'BAW'),
          ],
        ),
      );
    });

    test(
      'enriches route-search results with airports and airline name',
      () async {
        routeSearchApi.flights = <Map<String, dynamic>>[
          <String, dynamic>{
            'flightNumber': 'BA117',
            'fr24Id': 'track-123',
            'airlineCode': 'BAW',
            'origIcao': 'EGLL',
            'destIcao': 'KJFK',
            'historicalFlightDate': '2026-05-23',
            'actualDistanceKm': 5540.1,
            'actualDurationMinutes': 415,
          },
        ];

        final results = await repository.searchFlightsByRoute(
          departureCode: 'EGLL',
          arrivalCode: 'KJFK',
        );

        expect(results, hasLength(1));
        final result = results.single;
        expect(result.flightNumber, 'BA117');
        expect(result.fr24Id, 'track-123');
        expect(result.airlineName, 'British Airways');
        expect(result.departure?.icaoCode, 'EGLL');
        expect(result.arrival?.icaoCode, 'KJFK');
        expect(result.actualDurationMinutes, 415);
      },
    );

    test('skips route-search results that do not include a flight number', () async {
      routeSearchApi.flights = <Map<String, dynamic>>[
        <String, dynamic>{
          'airlineCode': 'VJT',
          'origIcao': 'EGLL',
          'destIcao': 'KJFK',
        },
        <String, dynamic>{
          'flightNumber': 'BA117',
          'airlineCode': 'BAW',
          'origIcao': 'EGLL',
          'destIcao': 'KJFK',
        },
      ];

      final results = await repository.searchFlightsByRoute(
        departureCode: 'EGLL',
        arrivalCode: 'KJFK',
      );

      expect(results, hasLength(1));
      expect(results.single.flightNumber, 'BA117');
    });

    test('surfaces firebase exception from route search api', () async {
      routeSearchApi.error = FirebaseFunctionsException(
        code: 'unavailable',
        message: 'try later',
      );

      await expectLater(
        repository.searchFlightsByRoute(
          departureCode: 'EGLL',
          arrivalCode: 'KJFK',
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });
  });
}

class _FakeFlightLookupApi extends FlightLookupApi {
  _FakeFlightLookupApi() : super();

  @override
  Future<Map<String, dynamic>> lookupFlightByNumber(String flightNumber) {
    throw UnimplementedError();
  }
}

class _FakeFlightRouteSearchApi extends FlightRouteSearchApi {
  _FakeFlightRouteSearchApi() : super();

  List<Map<String, dynamic>> flights = const <Map<String, dynamic>>[];
  Object? error;

  @override
  Future<List<Map<String, dynamic>>> searchFlightsByRoute({
    required String departureCode,
    required String arrivalCode,
  }) async {
    if (error != null) throw error!;
    return flights;
  }
}

class _FakeFlightRoutePreviewApi extends FlightRoutePreviewApi {
  _FakeFlightRoutePreviewApi() : super();

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
}

class _FakeFlightNumberSearchApi extends FlightNumberSearchApi {
  _FakeFlightNumberSearchApi() : super();

  @override
  Future<List<Map<String, dynamic>>> searchFlightsByNumber(String flightNumber) {
    throw UnimplementedError();
  }
}

class _FakeUpcomingFlightSearchApi extends UpcomingFlightSearchApi {
  _FakeUpcomingFlightSearchApi() : super();

  @override
  Future<List<Map<String, dynamic>>> searchUpcomingFlightsByNumber(
    String flightNumber,
  ) {
    throw UnimplementedError();
  }
}
