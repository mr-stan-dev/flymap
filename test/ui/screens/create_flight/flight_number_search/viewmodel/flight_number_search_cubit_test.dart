import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_flights_by_number_use_case.dart';
import 'package:flymap/domain/usecase/search_upcoming_flights_by_number_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_search_repository.dart';
import 'package:flymap/ui/screens/create_flight/flight_number_search/viewmodel/flight_number_search_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_number_search/viewmodel/flight_number_search_state.dart';
import 'package:latlong2/latlong.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('FlightNumberSearchCubit', () {
    late _FakeFlightSearchRepository repository;
    late _FakeAppAnalytics analytics;
    late _FakeAppCrashlytics crashlytics;
    late FlightNumberSearchCubit cubit;

    setUp(() {
      repository = _FakeFlightSearchRepository();
      analytics = _FakeAppAnalytics();
      crashlytics = _FakeAppCrashlytics();
      cubit = FlightNumberSearchCubit(
        searchFlightsByNumberUseCase: SearchFlightsByNumberUseCase(
          repository: repository,
        ),
        searchUpcomingFlightsByNumberUseCase:
            SearchUpcomingFlightsByNumberUseCase(repository: repository),
        analytics: analytics,
        crashlytics: crashlytics,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('shows specific not-found copy and analytics bucket', () async {
      repository.lookupError = _TestFirebaseFunctionsException(
        code: 'not-found',
        message: 'Flight not found',
        details: const {'reason': 'not_found', 'retryable': false},
      );

      await cubit.loadFlightSummary('BA117');

      final state = cubit.state;
      expect(state, isA<FlightNumberSearchError>());
      expect(
        (state as FlightNumberSearchError).message,
        'We couldn\'t find that flight number. Make sure it is the same as on your tickets and try again, or find by airports.',
      );
      final event = _eventNamed(analytics, 'flight_number_lookup_result');
      expect(event.firebaseParameters, <String, Object>{'result': 'not_found'});
      // The empty upcoming window is reported separately, so schedule
      // failures aren't masked by the historical fallback.
      final scheduleEvent = _eventNamed(analytics, 'schedule_lookup_result');
      expect(scheduleEvent.firebaseParameters, <String, Object>{
        'result': 'not_found',
        'source': 'number_search',
      });
      expect(crashlytics.lastFlightNumber, 'BA117');
    });

    test('rejects invalid flight number format before lookup', () async {
      await cubit.loadFlightSummary('5746');

      expect(cubit.state, isA<FlightNumberSearchInitial>());
      expect(analytics.logged, isEmpty);
      expect(crashlytics.lastFlightNumber, isNull);
    });

    test(
      'maps provider reasons to provider-specific copy and analytics',
      () async {
        repository.lookupError = _TestFirebaseFunctionsException(
          code: 'unavailable',
          message: 'Flight data is temporarily unavailable',
          details: const {
            'reason': 'provider_invalid_response',
            'retryable': true,
          },
        );

        await cubit.loadFlightSummary('BA117');

        final state = cubit.state;
        expect(state, isA<FlightNumberSearchError>());
        expect(
          (state as FlightNumberSearchError).message,
          'Flight data is temporarily unavailable. Please try again in a moment, or find by airports.',
        );
        expect(
          _eventNamed(analytics, 'flight_number_lookup_result')
              .firebaseParameters,
          <String, Object>{'result': 'provider_invalid_response'},
        );
      },
    );

    test('maps unexpected internal failures to unexpected error copy', () async {
      repository.lookupError = _TestFirebaseFunctionsException(
        code: 'internal',
        message: 'Failed to look up flight',
        details: const {'reason': 'internal', 'retryable': false},
      );

      await cubit.loadFlightSummary('BA117');

      final state = cubit.state;
      expect(state, isA<FlightNumberSearchError>());
      expect(
        (state as FlightNumberSearchError).message,
        'Something went wrong while looking up this flight. Please try again, or find by airports.',
      );
      expect(
        _eventNamed(analytics, 'flight_number_lookup_result')
            .firebaseParameters,
        <String, Object>{'result': 'internal'},
      );
    });

    test('maps invalid-argument failures to validation copy', () async {
      repository.lookupError = _TestFirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'Invalid request',
        details: const {'reason': 'invalid_argument', 'retryable': false},
      );

      await cubit.loadFlightSummary('BA117');

      final state = cubit.state;
      expect(state, isA<FlightNumberSearchError>());
      expect(
        (state as FlightNumberSearchError).message,
        'Enter a valid flight number like BA117.',
      );
      expect(
        _eventNamed(analytics, 'flight_number_lookup_result')
            .firebaseParameters,
        <String, Object>{'result': 'invalid_argument'},
      );
    });

    test('maps resource-exhausted failures to retry-later copy', () async {
      repository.lookupError = _TestFirebaseFunctionsException(
        code: 'resource-exhausted',
        message: 'Too many requests',
        details: const {'reason': 'resource_exhausted', 'retryable': true},
      );

      await cubit.loadFlightSummary('BA117');

      final state = cubit.state;
      expect(state, isA<FlightNumberSearchError>());
      expect(
        (state as FlightNumberSearchError).message,
        'Too many flight lookups right now. Please try again in a moment, or find by airports.',
      );
      expect(
        _eventNamed(analytics, 'flight_number_lookup_result')
            .firebaseParameters,
        <String, Object>{'result': 'resource_exhausted'},
      );
    });
  });
}

FirebaseAnalyticsEvent _eventNamed(_FakeAppAnalytics analytics, String name) {
  return analytics.logged.whereType<FirebaseAnalyticsEvent>().firstWhere(
    (event) => event.firebaseEventName == name,
  );
}

class _FakeFlightSearchRepository implements FlightSearchRepository {
  Object? lookupError;

  @override
  Future<Map<String, dynamic>> buildFlightRoutePreview({
    required String flightNumber,
    String? fr24Id,
    String? origCode,
    String? destCode,
    required int placesLimit,
    required int regionsLimit,
    String lang = 'en',
  }) {
    throw UnimplementedError();
  }


  @override
  Future<List<FlightSummary>> searchFlightsByNumber(String flightNumber) async {
    if (lookupError != null) {
      throw lookupError!;
    }
    return const <FlightSummary>[
      FlightSummary(
        flightNumber: 'BA117',
        fr24Id: 'track-1',
        origIcao: 'EGLL',
        destIcao: 'KJFK',
      ),
    ];
  }

  // Empty upcoming window: the cubit falls through to the historical search,
  // which is what these tests exercise.
  @override
  Future<List<FlightSummary>> searchUpcomingFlightsByNumber(
    String flightNumber,
  ) async {
    return const <FlightSummary>[];
  }

  @override
  Future<Airport> resolveAirport({
    LatLng? latLon,
    required String? code,
    required String fallbackName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String?> resolveAirlineNameByCode(String? code) async => null;

  @override
  Future<List<FlightSummary>> searchFlightsByRoute({
    required String departureCode,
    required String arrivalCode,
  }) {
    throw UnimplementedError();
  }
}

class _FakeAppAnalytics implements AppAnalytics {
  final List<AnalyticsEvent> logged = <AnalyticsEvent>[];

  @override
  Future<void> log(AnalyticsEvent event) async {
    logged.add(event);
  }

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {}

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {}
}

class _FakeAppCrashlytics implements AppCrashlytics {
  String? lastFlightNumber;

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setContext({
    String? screen,
    int? routeLengthKm,
    String? mapDetail,
    String? flightNumber,
    int? articlesSelectedCount,
    String? downloadStage,
  }) async {
    lastFlightNumber = flightNumber;
  }
}

class _TestFirebaseFunctionsException extends FirebaseFunctionsException {
  _TestFirebaseFunctionsException({
    required super.code,
    required super.message,
    super.details,
  });
}
