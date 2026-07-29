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

    // FR24 recorded legs FIRST: they carry everything the cards show
    // (route pairs, recorded duration/distance, aircraft) at no schedule-
    // provider cost. The schedule provider is consulted only as discovery
    // fallback for numbers FR24 has never recorded (brand-new/seasonal
    // routes) — and again with an exact date on the travel-date step,
    // which is the real "does it fly on my day" gate.
    Object? historicalError;
    try {
      final candidates = await _searchFlightsByNumberUseCase.call(normalized);
      if (candidates.isNotEmpty) {
        _logLookupResult(result: FlightNumberLookupResult.success);
        emit(
          FlightNumberSearchResultsLoaded(
            candidates: candidates,
            // Preselect the top (most recent) candidate so a single tap on
            // Continue works; users can still switch.
            selectedCandidate: candidates.first,
          ),
        );
        return;
      }
    } catch (error) {
      // Fall through to schedule discovery; a FR24 outage must not block
      // the flow if the schedule provider can still produce a card.
      historicalError = error;
    }

    try {
      final upcoming = await _searchUpcomingFlightsByNumberUseCase.call(
        normalized,
      );
      if (upcoming.isNotEmpty) {
        final groups = <String, List<FlightSummary>>{};
        for (final flight in upcoming) {
          groups.putIfAbsent(candidateGroupKey(flight), () => []).add(flight);
        }
        mergeIncompleteRouteGroups(groups);
        final representatives = groups.values
            .map(_preferCompleteRoute)
            .toList(growable: false);
        _logScheduleLookup(FlightNumberLookupResult.success);
        _logLookupResult(result: FlightNumberLookupResult.success);
        emit(
          FlightNumberSearchResultsLoaded(
            candidates: representatives,
            // Preselect the only (or first) flight so a single tap on
            // Continue works; users can still switch.
            selectedCandidate: representatives.first,
          ),
        );
        return;
      }
      _logScheduleLookup(FlightNumberLookupResult.notFound);
    } catch (error, stackTrace) {
      _reportScheduleFailure(error, stackTrace);
    }

    // Nothing from either source: surface the primary (historical) failure,
    // or honest not-found when both simply had nothing.
    final failureResult = historicalError != null
        ? flightNumberLookupResultFromError(historicalError)
        : FlightNumberLookupResult.notFound;
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

  /// The provider's currently-active leg often arrives with an INCOMPLETE
  /// arrival block (no destination codes), which would split the same
  /// flight into two cards — one of them a mystery with a blank arrival.
  /// Fold destination-less groups into the complete group with the same
  /// number + origin, but only when that match is unambiguous.
  static void mergeIncompleteRouteGroups(
    Map<String, List<FlightSummary>> groups,
  ) {
    final incompleteKeys = [
      for (final key in groups.keys)
        if (_isIncompleteRouteKey(key)) key,
    ];
    for (final key in incompleteKeys) {
      final prefix = key; // 'NUMBER|ORIG|'
      final siblings = [
        for (final other in groups.keys)
          if (other != key && other.startsWith(prefix)) other,
      ];
      if (siblings.length != 1) continue;
      groups[siblings.first]!.addAll(groups.remove(key)!);
    }
  }

  static bool _isIncompleteRouteKey(String key) {
    final parts = key.split('|');
    return parts.length == 3 && parts[1].isNotEmpty && parts[2].isEmpty;
  }

  /// Card representative: the first entry that knows its arrival (it also
  /// carries the stitched recorded facts); the active-leg entry with the
  /// blank arrival is never the face of the card.
  static FlightSummary _preferCompleteRoute(List<FlightSummary> group) {
    for (final flight in group) {
      final dest = flight.destIcao ?? flight.arrival?.icaoCode ?? '';
      if (dest.isNotEmpty) return flight;
    }
    return group.first;
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
      ),
    );
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
