import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/repository/flight_search_repository.dart';

class SearchUpcomingFlightsByNumberUseCase {
  SearchUpcomingFlightsByNumberUseCase({
    required FlightSearchRepository repository,
  }) : _repository = repository;

  final FlightSearchRepository _repository;

  Future<List<FlightSummary>> call(String flightNumber) {
    final normalized = flightNumber
        .replaceAll(RegExp(r'\s+'), '')
        .trim()
        .toUpperCase();
    return _repository.searchUpcomingFlightsByNumber(normalized);
  }
}
