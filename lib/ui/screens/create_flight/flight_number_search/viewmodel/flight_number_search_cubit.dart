import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_flights_by_number_use_case.dart';
import 'package:flymap/domain/usecase/search_upcoming_flights_by_number_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';

import 'flight_number_search_state.dart';
import 'flight_number_validator.dart';

class FlightNumberSearchCubit extends Cubit<FlightNumberSearchState> {
  FlightNumberSearchCubit({
    required SearchFlightsByNumberUseCase searchFlightsByNumberUseCase,
    required SearchUpcomingFlightsByNumberUseCase
    searchUpcomingFlightsByNumberUseCase,
    required AppAnalytics analytics,
    required AppCrashlytics crashlytics,
  }) : _searchFlightsByNumberUseCase = searchFlightsByNumberUseCase,
       _searchUpcomingFlightsByNumberUseCase =
           searchUpcomingFlightsByNumberUseCase,
       _analytics = analytics,
       _crashlytics = crashlytics,
       super(const FlightNumberSearchInitial());

  final SearchFlightsByNumberUseCase _searchFlightsByNumberUseCase;
  final SearchUpcomingFlightsByNumberUseCase
  _searchUpcomingFlightsByNumberUseCase;
  final AppAnalytics _analytics;
  final AppCrashlytics _crashlytics;

  Future<void> loadFlightSummary(String flightNumber) async {
    final normalized = _normalize(flightNumber);
    if (normalized == null) return;

    emit(const FlightNumberSearchLoading());

    // Upcoming scheduled departures first (next 7 days). The dated entries
    // are grouped per distinct flight (number + pair) so the user picks ONE
    // card here and the date on the dedicated travel-date step — seven
    // near-identical dated cards are impossible to tell apart. Any upcoming
    // failure degrades to the historical search rather than blocking the
    // flow.
    try {
      final upcoming = await _searchUpcomingFlightsByNumberUseCase.call(
        normalized,
      );
      if (upcoming.isNotEmpty) {
        final groups = <String, List<FlightSummary>>{};
        for (final flight in upcoming) {
          groups.putIfAbsent(candidateGroupKey(flight), () => []).add(flight);
        }
        final representatives = groups.values
            .map((group) => group.first)
            .toList(growable: false);
        _logScheduleLookup(FlightNumberLookupResult.success);
        _logLookupResult(result: FlightNumberLookupResult.success);
        emit(
          FlightNumberSearchResultsLoaded(
            candidates: representatives,
            // Preselect the only (or first) flight so a single tap on
            // Continue works; users can still switch.
            selectedCandidate: representatives.first,
            upcomingGroups: groups,
          ),
        );
        return;
      }
      _logScheduleLookup(FlightNumberLookupResult.notFound);
    } catch (error, stackTrace) {
      // Fall through to the historical search below, but keep the schedule
      // failure visible: rate limiting etc. would otherwise be masked by a
      // successful dateless fallback.
      _reportScheduleFailure(error, stackTrace);
    }

    try {
      final candidates = await _searchFlightsByNumberUseCase.call(normalized);
      _logLookupResult(result: FlightNumberLookupResult.success);
      emit(
        FlightNumberSearchResultsLoaded(
          candidates: candidates,
          // Preselect the top (most recent) candidate so a single tap on
          // Continue works; users can still switch.
          selectedCandidate: candidates.isEmpty ? null : candidates.first,
        ),
      );
    } catch (error) {
      final failureResult = flightNumberLookupResultFromError(error);
      _logLookupResult(result: failureResult);
      unawaited(
        _crashlytics.setContext(
          screen: 'flight_number_lookup_failed',
          flightNumber: normalized,
        ),
      );
      emit(
        FlightNumberSearchError(
          message: _lookupFailureMessage(failureResult),
          isRetryable: _isRetryableFailure(failureResult),
        ),
      );
    }
  }

  /// Groups dated departures of the same flight: one card per key.
  static String candidateGroupKey(FlightSummary flight) {
    final number = (flight.flightNumber ?? '').toUpperCase();
    final orig = (flight.origIcao ?? flight.departure?.icaoCode ?? '')
        .toUpperCase();
    final dest = (flight.destIcao ?? flight.arrival?.icaoCode ?? '')
        .toUpperCase();
    return '$number|$orig|$dest';
  }

  void selectCandidate(FlightSummary candidate) {
    final currentState = state;
    if (currentState is! FlightNumberSearchResultsLoaded) return;

    emit(
      FlightNumberSearchResultsLoaded(
        candidates: currentState.candidates,
        selectedCandidate: candidate,
        upcomingGroups: currentState.upcomingGroups,
      ),
    );
  }

  Future<void> confirmSummaryAndLoadRoute({
    required String flightNumber,
  }) async {
    final normalized = _normalize(flightNumber);
    final currentState = state;
    if (normalized == null ||
        currentState is! FlightNumberSearchResultsLoaded) {
      return;
    }

    final selectedCandidate = currentState.selectedCandidate;
    if (selectedCandidate == null ||
        selectedCandidate.departure == null ||
        selectedCandidate.arrival == null) {
      return;
    }

    emit(const FlightNumberSearchLoading());

    try {
      emit(
        FlightNumberSearchSuccess(
          departure: selectedCandidate.departure!,
          arrival: selectedCandidate.arrival!,
          flightNumber:
              _normalize(selectedCandidate.flightNumber ?? normalized) ??
              normalized,
          fr24Id: selectedCandidate.fr24Id,
          scheduleOptions:
              currentState.upcomingGroups[candidateGroupKey(
                selectedCandidate,
              )] ??
              const <FlightSummary>[],
        ),
      );
    } catch (_) {
      emit(
        FlightNumberSearchError(
          message: t.createFlight.flightNumberSearch.unexpectedError,
          candidates: currentState.candidates,
          selectedCandidate: currentState.selectedCandidate,
        ),
      );
    }
  }

  void clearSummary() {
    emit(const FlightNumberSearchInitial());
  }

  String? _normalize(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), '').trim().toUpperCase();
    if (normalized.isEmpty || !FlightNumberValidator.isValid(normalized)) {
      return null;
    }
    return normalized;
  }

  void _logLookupResult({required FlightNumberLookupResult result}) {
    _analytics.log(FlightNumberLookupResultEvent(result: result));
  }

  void _logScheduleLookup(FlightNumberLookupResult result) {
    _analytics.log(
      ScheduleLookupResultEvent(
        result: result,
        source: ScheduleLookupSource.numberSearch,
      ),
    );
  }

  void _reportScheduleFailure(Object error, StackTrace stackTrace) {
    final result = flightNumberLookupResultFromError(error);
    _logScheduleLookup(result);
    if (result.isProviderFailure) {
      unawaited(
        _crashlytics.recordError(
          error,
          stackTrace,
          reason: 'schedule_lookup_${result.analyticsValue}',
        ),
      );
    }
  }

  String _lookupFailureMessage(FlightNumberLookupResult result) {
    final lookupT = t.createFlight.flightNumberSearch;
    return switch (result) {
      FlightNumberLookupResult.notFound => lookupT.notFoundError,
      FlightNumberLookupResult.invalidArgument => lookupT.invalidFormatError,
      FlightNumberLookupResult.resourceExhausted => lookupT.rateLimitedError,
      FlightNumberLookupResult.providerUnavailable ||
      FlightNumberLookupResult.providerTimeout ||
      FlightNumberLookupResult.providerInvalidResponse =>
        lookupT.providerUnavailableError,
      _ => lookupT.unexpectedError,
    };
  }

  bool _isRetryableFailure(FlightNumberLookupResult result) {
    return switch (result) {
      FlightNumberLookupResult.notFound ||
      FlightNumberLookupResult.invalidArgument ||
      FlightNumberLookupResult.permissionDenied => false,
      _ => true,
    };
  }

}
