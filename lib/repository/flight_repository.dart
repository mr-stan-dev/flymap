import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_status.dart';

class FlightRepository {
  final FlightsDBService _flightsService;

  FlightRepository({required FlightsDBService service})
    : _flightsService = service;

  /// Insert a new flight
  Future<String> insertFlight(Flight flight) async {
    return await _flightsService.insertFlight(flight);
  }

  Future<String> saveOrUpdateFlight(Flight flight) async {
    return await _flightsService.saveOrUpdateFlight(flight);
  }

  Future<Flight?> getFlightById(String flightId) async {
    return await _flightsService.getFlightById(flightId);
  }

  Future<bool> updateFlightInfo({
    required String flightId,
    required FlightInfo info,
  }) async {
    return await _flightsService.updateFlightInfo(flightId, info);
  }

  Future<bool> updateFlightStatus({
    required String flightId,
    required FlightStatus status,
    DateTime? completedAt,
  }) async {
    return await _flightsService.updateFlightStatus(
      flightId,
      status,
      completedAt: completedAt,
    );
  }

  /// Marks a saved flight as a new access tier (e.g. Pro after a one-time
  /// unlock). Returns false if the flight no longer exists.
  Future<bool> updateFlightAccessTier({
    required String flightId,
    required String accessTier,
  }) async {
    return await _flightsService.updateFlightAccessTier(flightId, accessTier);
  }

  /// Persists a date/schedule on a saved flight that was created without one.
  Future<bool> updateFlightSchedule({
    required String flightId,
    required FlightSchedule schedule,
  }) async {
    return await _flightsService.updateFlightSchedule(flightId, schedule);
  }

  /// Get all flights
  Future<List<Flight>> getAllFlights() async {
    return await _flightsService.getAllFlights();
  }

  /// Get total flights count
  Future<int> getTotalFlights() async {
    return (await getAllFlights()).length;
  }

  /// Get total downloaded maps count.
  ///
  /// Maps are keyed by route, so two flights on the same route share one
  /// physical MBTiles file — counting per flight would double-count it.
  Future<int> getTotalDownloadedMaps() async {
    final flights = await _flightsService.getAllFlights();
    final uniqueFiles = <String>{};
    var pathlessMaps = 0;
    for (final f in flights) {
      for (final m in f.maps) {
        if (m.filePath.isEmpty) {
          pathlessMaps++;
        } else {
          uniqueFiles.add(m.filePath);
        }
      }
    }
    return uniqueFiles.length + pathlessMaps;
  }

  /// Get total map size in bytes, counting each shared physical file once.
  Future<int> getTotalMapSize() async {
    final flights = await _flightsService.getAllFlights();
    final seenFiles = <String>{};
    int totalBytes = 0;
    for (final f in flights) {
      for (final m in f.maps) {
        if (m.filePath.isNotEmpty && !seenFiles.add(m.filePath)) continue;
        totalBytes += m.sizeBytes;
      }
    }
    return totalBytes;
  }

  /// Get total distance of all flights in kilometers.
  Future<double> getTotalFlightDistanceKm() async {
    final flights = await _flightsService.getAllFlights();
    double totalDistance = 0;
    for (final flight in flights) {
      totalDistance += flight.route.distanceInKm;
    }
    return totalDistance;
  }
}
