import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/data/notifications/flight_notification_scheduler.dart';
import 'package:flymap/domain/usecase/flight_assets_deleter.dart';
import 'package:get_it/get_it.dart';

class DeleteFlightUseCase {
  DeleteFlightUseCase({required FlightsDBService service, FlightAssetsDeleter? assetsDeleter})
    : _service = service,
      _assetsDeleter =
          assetsDeleter ??
          FlightAssetsDeleter(getAllFlights: service.getAllFlights);

  final FlightsDBService _service;
  final FlightAssetsDeleter _assetsDeleter;

  Future<bool> call(String flightId) async {
    final flight = await _service.getFlightById(flightId);
    if (flight == null) return false;

    // Reference-counted: files shared with another flight on the same route
    // are kept (offline maps/articles are keyed by route, not flight).
    await _assetsDeleter.deleteAssets(flight);
    // A deleted flight must not ring later (guarded for tests without DI).
    if (GetIt.I.isRegistered<FlightNotificationScheduler>()) {
      await GetIt.I.get<FlightNotificationScheduler>().cancelForFlight(
        flightId,
      );
    }
    return _service.deleteFlightRecord(flightId);
  }
}
