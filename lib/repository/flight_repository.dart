import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_info.dart';

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

  /// Get all flights
  Future<List<Flight>> getAllFlights() async {
    return await _flightsService.getAllFlights();
  }

  /// Get total flights count
  Future<int> getTotalFlights() async {
    return (await getAllFlights()).length;
  }

  /// Get total downloaded maps count (sum of maps per flight)
  Future<int> getTotalDownloadedMaps() async {
    final flights = await _flightsService.getAllFlights();
    int total = 0;
    for (final f in flights) {
      total += f.maps.length;
    }
    return total;
  }

  /// Get total map size in bytes (sum of sizeBytes across all flight maps)
  Future<int> getTotalMapSize() async {
    final flights = await _flightsService.getAllFlights();
    int totalBytes = 0;
    for (final f in flights) {
      for (final m in f.maps) {
        totalBytes += m.sizeBytes;
      }
    }
    return totalBytes;
  }

}
