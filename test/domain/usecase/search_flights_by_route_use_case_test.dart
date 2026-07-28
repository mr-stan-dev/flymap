import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_flights_by_route_use_case.dart';
import 'package:flymap/repository/flight_search_repository.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('normalizes airport codes before delegating to repository', () async {
    final repository = _FakeFlightSearchRepository();
    final useCase = SearchFlightsByRouteUseCase(repository: repository);

    await useCase.call(departureCode: ' egll ', arrivalCode: ' kjfk ');

    expect(repository.lastDepartureCode, 'EGLL');
    expect(repository.lastArrivalCode, 'KJFK');
  });
}

class _FakeFlightSearchRepository implements FlightSearchRepository {
  String? lastDepartureCode;
  String? lastArrivalCode;

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
  Future<FlightSummary> lookupFlightByNumber(String flightNumber) {
    throw UnimplementedError();
  }

  @override
  Future<List<FlightSummary>> searchFlightsByNumber(String flightNumber) {
    throw UnimplementedError();
  }

  @override
  Future<List<FlightSummary>> searchUpcomingFlightsByNumber(
    String flightNumber,
  ) {
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
  Future<String?> resolveAirlineNameByCode(String? code) async => null;

  @override
  Future<List<FlightSummary>> searchFlightsByRoute({
    required String departureCode,
    required String arrivalCode,
  }) async {
    lastDepartureCode = departureCode;
    lastArrivalCode = arrivalCode;
    return const <FlightSummary>[];
  }
}
