import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';

sealed class FlightNumberSearchState {
  const FlightNumberSearchState();
}

class FlightNumberSearchInitial extends FlightNumberSearchState {
  const FlightNumberSearchInitial();
}

class FlightNumberSearchLoading extends FlightNumberSearchState {
  const FlightNumberSearchLoading();
}

class FlightNumberSearchResultsLoaded extends FlightNumberSearchState {
  /// One card per distinct flight (number + airport pair) — the date is
  /// picked on the dedicated travel-date step, not here.
  final List<FlightSummary> candidates;
  final FlightSummary? selectedCandidate;

  /// Dated 7-day departures per candidate, keyed by
  /// [FlightNumberSearchCubit.candidateGroupKey]. Empty for the historical
  /// fallback — the travel-date step then shows its generic day list.
  final Map<String, List<FlightSummary>> upcomingGroups;

  const FlightNumberSearchResultsLoaded({
    required this.candidates,
    required this.selectedCandidate,
    this.upcomingGroups = const {},
  });
}

class FlightNumberSearchError extends FlightNumberSearchState {
  final String message;

  /// True for transient failures (network, provider) where a retry may
  /// succeed; false for not-found / invalid input, where retrying the same
  /// query cannot help.
  final bool isRetryable;
  final List<FlightSummary> candidates;
  final FlightSummary? selectedCandidate;

  const FlightNumberSearchError({
    required this.message,
    this.isRetryable = true,
    this.candidates = const <FlightSummary>[],
    this.selectedCandidate,
  });
}

class FlightNumberSearchSuccess extends FlightNumberSearchState {
  final Airport departure;
  final Airport arrival;
  final String flightNumber;
  final String? fr24Id;

  /// Dated departures for the confirmed flight, passed on to the
  /// travel-date step. Empty when the schedule is unknown.
  final List<FlightSummary> scheduleOptions;

  const FlightNumberSearchSuccess({
    required this.departure,
    required this.arrival,
    required this.flightNumber,
    this.fr24Id,
    this.scheduleOptions = const <FlightSummary>[],
  });
}
