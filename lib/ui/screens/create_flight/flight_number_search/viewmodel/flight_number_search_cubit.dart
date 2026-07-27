import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_flights_by_number_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';

import 'flight_number_search_state.dart';
import 'flight_number_validator.dart';

class FlightNumberSearchCubit extends Cubit<FlightNumberSearchState> {
  FlightNumberSearchCubit({
    required SearchFlightsByNumberUseCase searchFlightsByNumberUseCase,
    required AppAnalytics analytics,
    required AppCrashlytics crashlytics,
  }) : _searchFlightsByNumberUseCase = searchFlightsByNumberUseCase,
       _analytics = analytics,
       _crashlytics = crashlytics,
       super(const FlightNumberSearchInitial());

  final SearchFlightsByNumberUseCase _searchFlightsByNumberUseCase;
  final AppAnalytics _analytics;
  final AppCrashlytics _crashlytics;

  Future<void> loadFlightSummary(String flightNumber) async {
    final normalized = _normalize(flightNumber);
    if (normalized == null) return;

    emit(const FlightNumberSearchLoading());

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
      final failureResult = _lookupFailureResult(error);
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

  FlightNumberLookupResult _lookupFailureResult(Object error) {
    if (error is FirebaseFunctionsException) {
      final reason = _lookupFailureReason(error.details);
      return switch (error.code) {
        'not-found' => FlightNumberLookupResult.notFound,
        'unavailable' => switch (reason) {
          'provider_timeout' => FlightNumberLookupResult.providerTimeout,
          'provider_invalid_response' =>
            FlightNumberLookupResult.providerInvalidResponse,
          _ => FlightNumberLookupResult.providerUnavailable,
        },
        'invalid-argument' => FlightNumberLookupResult.invalidArgument,
        'permission-denied' => FlightNumberLookupResult.permissionDenied,
        'resource-exhausted' => FlightNumberLookupResult.resourceExhausted,
        'deadline-exceeded' => FlightNumberLookupResult.deadlineExceeded,
        'internal' => FlightNumberLookupResult.internal,
        _ => FlightNumberLookupResult.failed,
      };
    }
    return FlightNumberLookupResult.failed;
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

  String? _lookupFailureReason(Object? details) {
    if (details is Map) {
      final dynamic reason = details['reason'];
      if (reason is String && reason.isNotEmpty) {
        return reason;
      }
    }
    return null;
  }
}
