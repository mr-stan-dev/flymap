import 'package:flymap/data/api/flight_lookup_api.dart';
import 'package:flymap/data/api/flight_number_search_api.dart';
import 'package:flymap/data/api/flight_route_preview_api.dart';
import 'package:flymap/data/api/flight_route_search_api.dart';
import 'package:flymap/data/api/upcoming_flight_search_api.dart';
import 'package:flymap/data/local/airlines_database.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:latlong2/latlong.dart';

abstract interface class FlightSearchRepository {
  Future<FlightSummary> lookupFlightByNumber(String flightNumber);

  Future<List<FlightSummary>> searchFlightsByNumber(String flightNumber);

  /// Upcoming scheduled departures (7-day window) for a flight number,
  /// dated and stitched to recorded FR24 legs. Throws `not-found` when the
  /// number has no departures in the window.
  Future<List<FlightSummary>> searchUpcomingFlightsByNumber(
    String flightNumber,
  );

  Future<List<FlightSummary>> searchFlightsByRoute({
    required String departureCode,
    required String arrivalCode,
  });

  Future<Map<String, dynamic>> buildFlightRoutePreview({
    required String flightNumber,
    String? fr24Id,
    String? origCode,
    String? destCode,
    required int placesLimit,
    required int regionsLimit,
    String lang = 'en',
  });

  Future<Airport> resolveAirport({
    LatLng? latLon,
    required String? code,
    required String fallbackName,
  });

  Future<String?> resolveAirlineNameByCode(String? code);
}

class ApiFlightSearchRepository implements FlightSearchRepository {
  ApiFlightSearchRepository({
    required FlightLookupApi lookupApi,
    required FlightNumberSearchApi numberSearchApi,
    required UpcomingFlightSearchApi upcomingSearchApi,
    required FlightRouteSearchApi routeSearchApi,
    required FlightRoutePreviewApi routePreviewApi,
    required AirportsDatabase airportsDb,
    required AirlinesDatabase airlinesDb,
  }) : _lookupApi = lookupApi,
       _numberSearchApi = numberSearchApi,
       _upcomingSearchApi = upcomingSearchApi,
       _routeSearchApi = routeSearchApi,
       _routePreviewApi = routePreviewApi,
       _airportsDb = airportsDb,
       _airlinesDb = airlinesDb;

  final FlightLookupApi _lookupApi;
  final FlightNumberSearchApi _numberSearchApi;
  final UpcomingFlightSearchApi _upcomingSearchApi;
  final FlightRouteSearchApi _routeSearchApi;
  final FlightRoutePreviewApi _routePreviewApi;
  final AirportsDatabase _airportsDb;
  final AirlinesDatabase _airlinesDb;
  final _logger = const Logger('FlightSearchRepository');

  @override
  Future<FlightSummary> lookupFlightByNumber(String flightNumber) async {
    final map = await _lookupApi.lookupFlightByNumber(flightNumber);
    return FlightSummary.fromApi(map, flightNumber);
  }

  @override
  Future<List<FlightSummary>> searchFlightsByNumber(String flightNumber) async {
    final flights = await _numberSearchApi.searchFlightsByNumber(flightNumber);
    return _enrichFlightSummaries(flights, logPrefix: 'numberMatch');
  }

  @override
  Future<List<FlightSummary>> searchUpcomingFlightsByNumber(
    String flightNumber,
  ) async {
    final flights = await _upcomingSearchApi.searchUpcomingFlightsByNumber(
      flightNumber,
    );
    return _enrichFlightSummaries(flights, logPrefix: 'upcomingMatch');
  }

  @override
  Future<List<FlightSummary>> searchFlightsByRoute({
    required String departureCode,
    required String arrivalCode,
  }) async {
    final flights = await _routeSearchApi.searchFlightsByRoute(
      departureCode: departureCode,
      arrivalCode: arrivalCode,
    );

    return _enrichFlightSummaries(flights, logPrefix: 'routeMatch');
  }

  @override
  Future<Map<String, dynamic>> buildFlightRoutePreview({
    required String flightNumber,
    String? fr24Id,
    String? origCode,
    String? destCode,
    required int placesLimit,
    required int regionsLimit,
    String lang = 'en',
  }) async {
    return await _routePreviewApi.buildFlightRoutePreview(
      flightNumber: flightNumber,
      fr24Id: fr24Id,
      origCode: origCode,
      destCode: destCode,
      placesLimit: placesLimit,
      regionsLimit: regionsLimit,
      lang: lang,
    );
  }

  @override
  Future<Airport> resolveAirport({
    LatLng? latLon,
    required String? code,
    required String fallbackName,
  }) async {
    await _airportsDb.initialize();

    final trimmedCode = _normalizeCode(code);
    if (trimmedCode != null) {
      final byCode = _airportsDb.findByCode(trimmedCode);
      if (byCode != null) return byCode;
    }

    final effectiveLatLon = latLon ?? const LatLng(0, 0);

    if (latLon != null) {
      final nearest = _findNearestAirport(latLon);
      if (nearest != null) return nearest;
    }

    final fallbackCode = trimmedCode ?? '';
    return Airport(
      name: fallbackCode.isNotEmpty ? fallbackCode : fallbackName,
      city: '',
      countryCode: '',
      latLon: effectiveLatLon,
      iataCode: fallbackCode.length == 3 ? fallbackCode : '',
      icaoCode: fallbackCode.length == 4 ? fallbackCode : '',
      wikipediaUrl: '',
      type: AirportType.other,
    );
  }

  Airport? _findNearestAirport(LatLng target) {
    Airport? bestAirport;
    var bestDistanceKm = double.infinity;
    for (final airport in _airportsDb.allAirports) {
      final distanceKm = MapUtils.distanceKm(
        departure: target,
        arrival: airport.latLon,
      );
      if (distanceKm < bestDistanceKm) {
        bestDistanceKm = distanceKm;
        bestAirport = airport;
      }
    }
    if (bestDistanceKm <= 120) {
      return bestAirport;
    }
    return null;
  }

  String? _normalizeCode(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim().toUpperCase();
    return value.isEmpty ? null : value;
  }

  @override
  Future<String?> resolveAirlineNameByCode(String? code) async {
    final normalizedCode = _normalizeCode(code);
    if (normalizedCode == null) return null;

    await _airlinesDb.initialize();
    return _airlinesDb.findNameByCode(normalizedCode);
  }

  Future<List<FlightSummary>> _enrichFlightSummaries(
    List<Map<String, dynamic>> flights, {
    required String logPrefix,
  }) async {
    final summaries = <FlightSummary>[];
    for (final flight in flights) {
      final fallbackFlightNumber = _normalizeCode(flight['flightNumber']);
      if (fallbackFlightNumber == null) {
        continue;
      }
      final summary = FlightSummary.fromApi(flight, fallbackFlightNumber);
      final departure = await resolveAirport(
        code: summary.origIcao ?? _normalizeCode(flight['origIata']),
        fallbackName: 'Departure',
      );
      final arrival = await resolveAirport(
        code: summary.destIcao ?? _normalizeCode(flight['destIata']),
        fallbackName: 'Arrival',
      );
      final airlineName = await resolveAirlineNameByCode(summary.airlineCode);
      _logger.log(
        '$logPrefix flightNumber=${summary.flightNumber ?? "-"} fr24Id=${summary.fr24Id ?? "-"} airlineCode=${summary.airlineCode ?? "-"} airlineName=${airlineName ?? summary.airlineName ?? "-"} departure=${departure.displayCode} arrival=${arrival.displayCode}',
      );

      summaries.add(
        summary.copyWith(
          departure: departure,
          arrival: arrival,
          airlineName: airlineName ?? summary.airlineName ?? '',
        ),
      );
    }
    return summaries;
  }
}
