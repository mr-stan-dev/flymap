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

  const FlightNumberSearchResultsLoaded({
    required this.candidates,
    required this.selectedCandidate,
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
