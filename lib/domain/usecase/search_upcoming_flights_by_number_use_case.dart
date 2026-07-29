import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/repository/flight_search_repository.dart';

class SearchUpcomingFlightsByNumberUseCase {
  SearchUpcomingFlightsByNumberUseCase({
    required FlightSearchRepository repository,
  }) : _repository = repository;

  final FlightSearchRepository _repository;

  /// [date]: exact-date verification for that local day instead of the
  /// default 7-day window.
  Future<List<FlightSummary>> call(String flightNumber, {DateTime? date}) {
    final normalized = flightNumber
        .replaceAll(RegExp(r'\s+'), '')
        .trim()
        .toUpperCase();
    return _repository.searchUpcomingFlightsByNumber(normalized, date: date);
  }
}
