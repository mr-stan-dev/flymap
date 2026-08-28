import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/repository/flight_repository.dart';

/// Returns an archived flight to the active list without changing its saved
/// map or offline content.
class RestoreFlightUseCase {
  RestoreFlightUseCase({required FlightRepository repository})
    : _repository = repository;

  final FlightRepository _repository;

  Future<bool> call({required String flightId}) {
    return _repository.updateFlightStatus(
      flightId: flightId,
      status: FlightStatus.upcoming,
    );
  }
}
