import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/usecase/flight_assets_deleter.dart';

class CompleteFlightUseCase {
  CompleteFlightUseCase({
    required FlightsDBService service,
    FlightAssetsDeleter? assetsDeleter,
  }) : _service = service,
       _assetsDeleter =
           assetsDeleter ??
           FlightAssetsDeleter(getAllFlights: service.getAllFlights);

  final FlightsDBService _service;
  final FlightAssetsDeleter _assetsDeleter;

  Future<bool> call({
    required String flightId,
    required bool deleteOfflineData,
  }) async {
    final flight = await _service.getFlightById(flightId);
    if (flight == null) return false;
    if (!deleteOfflineData) {
      return _service.updateFlightStatus(
        flightId,
        FlightStatus.completed,
        completedAt: DateTime.now(),
      );
    }

    // Reference-counted: files shared with another flight on the same route
    // are kept (offline maps/articles are keyed by route, not flight).
    await _assetsDeleter.deleteAssets(flight);

    final updated = Flight(
      id: flight.id,
      route: flight.route,
      maps: const [],
      routeInsights: flight.routeInsights,
      offlineContent: flight.offlineContent.copyWith(articles: const []),
      timestamp: flight.timestamp.copyWith(
        clearInProgressAt: true,
        completedAt: DateTime.now(),
      ),
      status: FlightStatus.completed,
      flightAccessTier: flight.flightAccessTier,
      operationalData: flight.operationalData,
    );
    await _service.saveOrUpdateFlight(updated);
    return true;
  }
}
