import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_flights_by_number_use_case.dart';
import 'package:flymap/domain/usecase/search_upcoming_flights_by_number_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_search_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/flight_number_search/flight_number_search_screen.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('shows find-by-airports action in idle state', (tester) async {
    await _registerScreenDependencies();

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Or enter Airports'), findsOneWidget);
  });

  testWidgets(
    'shows validation copy only after a search attempt with invalid input',
    (tester) async {
      final repository = _FakeFlightSearchRepository();
      await _registerScreenDependencies(repository: repository);

      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '5746');
      await tester.pump();

      // No nagging while typing.
      expect(
        find.text('Enter a valid flight number like BA117.'),
        findsNothing,
      );

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // The attempt surfaces the validation error and no lookup happens.
      expect(
        find.text('Enter a valid flight number like BA117.'),
        findsOneWidget,
      );
      expect(repository.searchCallCount, 0);
    },
  );

  testWidgets('shows find-by-airports action after lookup error', (
    tester,
  ) async {
    final repository = _FakeFlightSearchRepository()
      ..lookupError = FirebaseFunctionsException(
        code: 'not-found',
        message: 'missing',
      );
    await _registerScreenDependencies(repository: repository);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'BA117');
    await tester.pump();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Or enter Airports'), findsNothing);
    expect(find.text('Find by airports'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('hides find-by-airports action after successful lookup', (
    tester,
  ) async {
    await _registerScreenDependencies();

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'BA117');
    await tester.pump();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Or enter Airports'), findsNothing);
  });

  testWidgets('routes to real-route airport search screen', (tester) async {
    await _registerScreenDependencies();

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Or enter Airports'));
    await tester.pumpAndSettle();

    expect(find.text('airport search route'), findsOneWidget);
  });
}

Future<void> _registerScreenDependencies({
  _FakeFlightSearchRepository? repository,
}) async {
  final searchRepository = repository ?? _FakeFlightSearchRepository();
  GetIt.I.registerSingleton<FlightSearchRepository>(searchRepository);
  GetIt.I.registerSingleton<SearchFlightsByNumberUseCase>(
    SearchFlightsByNumberUseCase(repository: searchRepository),
  );
  GetIt.I.registerSingleton<SearchUpcomingFlightsByNumberUseCase>(
    SearchUpcomingFlightsByNumberUseCase(repository: searchRepository),
  );
  GetIt.I.registerSingleton<AppAnalytics>(_FakeAppAnalytics());
  GetIt.I.registerSingleton<AppCrashlytics>(_FakeAppCrashlytics());
}

Widget _testApp() {
  final router = GoRouter(
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const FlightNumberSearchScreen(hasPendingFlightUnlock: true),
      ),
      GoRoute(
        path: AppRouter.realRouteAirportSearchRoute,
        builder: (context, state) =>
            const Scaffold(body: Text('airport search route')),
      ),
    ],
  );

  return TranslationProvider(
    child: MaterialApp.router(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    ),
  );
}

class _FakeFlightSearchRepository implements FlightSearchRepository {
  Object? lookupError;
  int searchCallCount = 0;

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
  Future<FlightSummary> lookupFlightByNumber(String flightNumber) async {
    throw UnimplementedError();
  }

  @override
  Future<List<FlightSummary>> searchFlightsByNumber(String flightNumber) async {
    searchCallCount += 1;
    if (lookupError != null) throw lookupError!;
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
  }) async {
    return Airport(
      name: fallbackName,
      city: '',
      countryCode: '',
      latLon: latLon ?? const LatLng(0, 0),
      iataCode: '',
      icaoCode: code ?? '',
      wikipediaUrl: '',
    );
  }

  @override
  Future<String?> resolveAirlineNameByCode(String? code) async => null;

  @override
  Future<List<FlightSummary>> searchFlightsByRoute({
    required String departureCode,
    required String arrivalCode,
  }) async {
    return const <FlightSummary>[];
  }
}

class _FakeAppAnalytics implements AppAnalytics {
  @override
  Future<void> log(AnalyticsEvent event) async {}

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
  }) async {}
}
