import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/flights_service.dart';
import 'package:flymap/data/local/maps_service.dart';
import 'package:flymap/entity/flight.dart';

class FlightRepository {
  final FlightsService _flightsService;
  final MapsService _mapsService;

  FlightRepository({required AppDatabase database})
    : _flightsService = FlightsService(database: database),
      _mapsService = MapsService(database: database);

  /// Insert a new flight
  Future<String> insertFlight(Flight flight) async {
    return await _flightsService.insertFlight(flight);
  }

  /// Update an existing flight
  Future<bool> updateFlight(Flight flight) async {
    return await _flightsService.updateFlight(flight);
  }

  /// Get all flights
  Future<List<Flight>> getAllFlights() async {
    return await _flightsService.getAllFlights();
  }

  /// Get total flights count
  Future<int> getTotalFlights() async {
    return (await getAllFlights()).length;
  }

  /// Get total downloaded maps count
  Future<int> getTotalDownloadedMaps() async {
    return await _mapsService.getTotalDownloadedMaps();
  }

  /// Get total map size in bytes
  Future<int> getTotalMapSize() async {
    return await _mapsService.getTotalMapSize();
  }

  /// Delete flight by ID
  Future<bool> deleteFlight(String flightId) async {
    return await _flightsService.deleteFlight(flightId);
  }

  /// Delete all maps for a given flight
  Future<void> deleteMapsForFlight(String flightId) async {
    await _mapsService.deleteFlightMaps(flightId);
  }
}
