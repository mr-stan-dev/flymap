import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/data/location/app_location_client.dart';
import 'package:flymap/data/location/app_location_service.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/domain/entity/learn_access.dart';
import 'package:flymap/domain/entity/learn_article_content.dart';
import 'package:flymap/domain/entity/learn_article_meta.dart';
import 'package:flymap/domain/entity/learn_article_progress.dart';
import 'package:flymap/domain/entity/learn_category.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/feature_announcement_repository.dart';
import 'package:flymap/repository/geo_quiz_progress_repository.dart';
import 'package:flymap/repository/geo_quiz_repository.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';
import 'package:flymap/repository/learn_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/rating/rate_prompt_policy_service.dart';
import 'package:flymap/rating/rate_prompt_trigger.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:flymap/repository/settings_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/repository/user_flight_prefs_storage.dart';
import 'package:flymap/subscription/flight_unlock_product.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/screens/home/home_screen.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_screen.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_session_factory.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_export_service.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_share_service.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flight_card.dart';
import 'package:sky_camera/sky_camera.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:flymap/domain/usecase/can_open_learn_article_use_case.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_article_content_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_article_progress_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_categories_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_category_articles_use_case.dart';
import 'package:flymap/domain/usecase/mark_learn_article_seen_use_case.dart';
import 'package:flymap/domain/usecase/toggle_learn_article_favorite_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _FakeSkyCameraMediaRepository mediaRepository;

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    mediaRepository = _FakeSkyCameraMediaRepository();
    GetIt.I.registerSingleton<FlightRepository>(const _FakeFlightRepository());
    GetIt.I.registerSingleton<DeleteFlightUseCase>(_FakeDeleteFlightUseCase());
    GetIt.I.registerSingleton<ConnectivityChecker>(
      const _FakeConnectivityChecker(),
    );
    GetIt.I.registerSingleton<RatePromptPolicyService>(
      const _FakeRatePromptPolicyService(),
    );
    GetIt.I.registerSingleton<OnboardingRepository>(
      OnboardingRepository(prefsStorage: UserFlightPrefsStorage()),
    );
    GetIt.I.registerSingleton<FeatureAnnouncementRepository>(
      FeatureAnnouncementRepository(
        onboarding: GetIt.I.get<OnboardingRepository>(),
      ),
    );
    final learnRepository = _FakeLearnRepository();
    GetIt.I.registerSingleton<GetLearnCategoriesUseCase>(
      GetLearnCategoriesUseCase(repository: learnRepository),
    );
    GetIt.I.registerSingleton<GetLearnCategoryArticlesUseCase>(
      GetLearnCategoryArticlesUseCase(repository: learnRepository),
    );
    GetIt.I.registerSingleton<GetLearnArticleContentUseCase>(
      GetLearnArticleContentUseCase(repository: learnRepository),
    );
    final learnProgressRepository = _InMemoryLearnArticleProgressRepository();
    GetIt.I.registerSingleton<GetLearnArticleProgressUseCase>(
      GetLearnArticleProgressUseCase(repository: learnProgressRepository),
    );
    GetIt.I.registerSingleton<ToggleLearnArticleFavoriteUseCase>(
      ToggleLearnArticleFavoriteUseCase(repository: learnProgressRepository),
    );
    GetIt.I.registerSingleton<MarkLearnArticleSeenUseCase>(
      MarkLearnArticleSeenUseCase(repository: learnProgressRepository),
    );
    GetIt.I.registerSingleton<CanOpenLearnArticleUseCase>(
      CanOpenLearnArticleUseCase(repository: learnRepository),
    );
    GetIt.I.registerSingleton<GeoQuizRepository>(
      const _FakeGeoQuizRepository(),
    );
    GetIt.I.registerSingleton<GeoQuizProgressRepository>(
      SharedPrefsGeoQuizProgressRepository(),
    );
    GetIt.I.registerSingleton<SkyCameraMediaRepository>(mediaRepository);
    GetIt.I.registerSingleton<AppAnalytics>(const _FakeAppAnalytics());
    GetIt.I.registerSingleton<MetricUnitsRepository>(MetricUnitsRepository());
    GetIt.I.registerSingleton<SettingsRepository>(SettingsRepository());
    GetIt.I.registerSingleton<FlymapSkyCameraSessionFactory>(
      _FakeFlymapSkyCameraSessionFactory(mediaRepository: mediaRepository),
    );
    GetIt.I.registerFactoryParam<GeoQuizListCubit, String, Object?>(
      (collectionId, _) => GeoQuizListCubit(
        collectionId: collectionId,
        repository: GetIt.I.get(),
        progressRepository: GetIt.I.get(),
        analytics: GetIt.I.get(),
      ),
    );
    GetIt.I.registerFactoryParam<GeoQuizCubit, GeoQuizSummary, bool>(
      (summary, isProUser) => GeoQuizCubit(
        summary: summary,
        repository: GetIt.I.get(),
        progressRepository: GetIt.I.get(),
        languageCodeProvider: () => 'en',
        analytics: GetIt.I.get(),
        isProUser: isProUser,
        nowProvider: DateTime.now,
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
    await mediaRepository.dispose();
  });

  testWidgets('defaults to Flights tab with dynamic app bar title', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);

    expect(_findAppBarTitle('Flights'), findsOneWidget);
    expect(find.text('New flight'), findsOneWidget);
    expect(find.byKey(homeFlightsTabKey), findsOneWidget);
    expect(find.byKey(homeLearnTabKey), findsOneWidget);
    expect(find.byKey(homeMediaTabKey), findsOneWidget);
    expect(find.byKey(homeSettingsTabKey), findsOneWidget);
  });

  testWidgets('switches to Learn tab and keeps app stable', (tester) async {
    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);

    await tester.tap(find.byKey(homeLearnTabKey));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_findAppBarTitle('Learn'), findsOneWidget);
  });

  testWidgets(
    'shows camera FAB in Media tab and opens camera with no flights',
    (tester) async {
      await tester.pumpWidget(_testApp());
      await _pumpForInitialLoad(tester);

      expect(find.byKey(homeSkyCameraButtonKey), findsNothing);

      await tester.tap(find.byKey(homeMediaTabKey));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(homeSkyCameraButtonKey), findsOneWidget);
      await tester.ensureVisible(find.byKey(homeSkyCameraButtonKey));

      await tester.tap(find.byKey(homeSkyCameraButtonKey), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('test.sky_camera.preview')), findsOneWidget);
      expect(find.textContaining('LHR'), findsNothing);
      expect(find.textContaining('BCN'), findsNothing);
    },
  );

  testWidgets('camera startup can finish after its route is closed', (
    tester,
  ) async {
    final flightsCompleter = Completer<List<Flight>>();
    final flightRepository = _DelayedFlightRepository(flightsCompleter);
    await GetIt.I.unregister<FlymapSkyCameraSessionFactory>();
    GetIt.I.registerSingleton<FlymapSkyCameraSessionFactory>(
      _FakeFlymapSkyCameraSessionFactory(
        mediaRepository: mediaRepository,
        flightRepository: flightRepository,
      ),
    );

    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);
    await tester.tap(find.byKey(homeMediaTabKey));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.ensureVisible(find.byKey(homeSkyCameraButtonKey));
    await tester.tap(find.byKey(homeSkyCameraButtonKey), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    Navigator.of(tester.element(find.byType(CircularProgressIndicator))).pop();
    await tester.pump();
    flightsCompleter.complete(const <Flight>[]);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('camera launched for a flight keeps that exact flight context', (
    tester,
  ) async {
    final selectedFlight = _buildFlight(
      id: 'selected-flight',
      status: FlightStatus.completed,
    );
    final newerActiveFlight = _buildFlight(
      id: 'newer-active-flight',
      status: FlightStatus.inProgress,
    );
    final factory = _FakeFlymapSkyCameraSessionFactory(
      mediaRepository: mediaRepository,
      flightRepository: _FakeFlightRepository(
        flights: [newerActiveFlight, selectedFlight],
      ),
    );
    await GetIt.I.unregister<FlymapSkyCameraSessionFactory>();
    GetIt.I.registerSingleton<FlymapSkyCameraSessionFactory>(factory);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: FlymapSkyCameraScreen.forFlight(flightId: selectedFlight.id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(factory.createdForFlightId, selectedFlight.id);
    expect(find.textContaining('LHR'), findsOneWidget);
  });

  testWidgets(
    'shows Learn new feature dot for existing users and clears it on open',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding.seen', true);

      await tester.pumpWidget(_testApp());
      await _pumpForInitialLoad(tester);

      expect(find.byKey(homeLearnGeoQuizDotKey), findsOneWidget);

      await tester.tap(find.byKey(homeLearnTabKey));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(homeLearnGeoQuizDotKey), findsNothing);
      expect(find.byKey(const Key('learn.geo_quiz.new_badge')), findsOneWidget);
      expect(
        prefs.getBool(
          FeatureAnnouncementRepository.seenKey(
            FeatureAnnouncement.geoQuizLearn,
          ),
        ),
        isTrue,
      );
    },
  );

  testWidgets('switches to Settings tab and renders settings content', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);

    await tester.tap(find.byKey(homeSettingsTabKey));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_findAppBarTitle('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('switches to Media tab and renders empty media state', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);

    await tester.tap(find.byKey(homeMediaTabKey));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_findAppBarTitle('Window Seat Media'), findsOneWidget);
    expect(find.text('Welcome to your window-seat Sky Camera'), findsOneWidget);
    expect(
      find.text(
        'Capture and share beautiful views from your window seat with flight and GPS data overlays.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Media tab shows no-flight captures in the top horizontal section',
    (tester) async {
      await GetIt.I.unregister<SkyCameraMediaRepository>();
      mediaRepository = _FakeSkyCameraMediaRepository(
        captures: [
          _buildMediaItem(
            id: 'capture-no-flight',
            capturedAt: DateTime(2026, 7, 2, 12, 0),
          ),
        ],
      );
      GetIt.I.registerSingleton<SkyCameraMediaRepository>(mediaRepository);

      await tester.pumpWidget(_testApp());
      await _pumpForInitialLoad(tester);

      await tester.tap(find.byKey(homeMediaTabKey));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No flight context'), findsOneWidget);
      expect(
        find.text('Captures taken outside an active flight'),
        findsOneWidget,
      );
      expect(find.byType(Card), findsWidgets);
      final thumbnailSize = tester.getSize(
        find.byKey(const Key('media.strip_thumbnail_capture-no-flight')),
      );
      expect(thumbnailSize.width, thumbnailSize.height);
      expect(find.text('View all'), findsNothing);
    },
  );

  testWidgets('deletes the last pager item after Media refresh', (
    tester,
  ) async {
    await GetIt.I.unregister<SkyCameraMediaRepository>();
    mediaRepository = _FakeSkyCameraMediaRepository(
      captures: [
        _buildMediaItem(
          id: 'capture-only',
          capturedAt: DateTime(2026, 7, 2, 12, 0),
        ),
      ],
    );
    GetIt.I.registerSingleton<SkyCameraMediaRepository>(mediaRepository);

    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);
    await tester.tap(find.byKey(homeMediaTabKey));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find.byKey(const Key('media.strip_thumbnail_capture-only')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('media.capture_preview_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete file'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome to your window-seat Sky Camera'), findsOneWidget);
  });

  testWidgets(
    'Media tab hides view all for flight groups with 10 or fewer files',
    (tester) async {
      await GetIt.I.unregister<FlightRepository>();
      GetIt.I.registerSingleton<FlightRepository>(
        _FakeFlightRepository(
          flights: [
            _buildFlight(id: 'flight-1', status: FlightStatus.completed),
          ],
        ),
      );
      await GetIt.I.unregister<SkyCameraMediaRepository>();
      mediaRepository = _FakeSkyCameraMediaRepository(
        captures: [
          _buildMediaItem(
            id: 'capture-flight-1',
            capturedAt: DateTime(2026, 7, 2, 12, 0),
            flightId: 'flight-1',
          ),
        ],
      );
      GetIt.I.registerSingleton<SkyCameraMediaRepository>(mediaRepository);

      await tester.pumpWidget(_testApp());
      await _pumpForInitialLoad(tester);

      await tester.tap(find.byKey(homeMediaTabKey));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('LHR - MUC'), findsOneWidget);
      expect(find.text('London - Munich'), findsOneWidget);
      expect(find.text('View all'), findsNothing);
    },
  );

  testWidgets(
    'Media tab shows view all for no-flight and flight groups with more than 10 files',
    (tester) async {
      await GetIt.I.unregister<FlightRepository>();
      GetIt.I.registerSingleton<FlightRepository>(
        _FakeFlightRepository(
          flights: [
            _buildFlight(id: 'flight-1', status: FlightStatus.completed),
          ],
        ),
      );
      await GetIt.I.unregister<SkyCameraMediaRepository>();
      mediaRepository = _FakeSkyCameraMediaRepository(
        captures: [
          for (var i = 0; i < 11; i++)
            _buildMediaItem(
              id: 'capture-no-flight-$i',
              capturedAt: DateTime(2026, 7, 2, 12, i),
            ),
          for (var i = 0; i < 11; i++)
            _buildMediaItem(
              id: 'capture-flight-$i',
              capturedAt: DateTime(2026, 7, 1, 12, i),
              flightId: 'flight-1',
            ),
        ],
      );
      GetIt.I.registerSingleton<SkyCameraMediaRepository>(mediaRepository);

      await tester.pumpWidget(_testApp());
      await _pumpForInitialLoad(tester);

      await tester.tap(find.byKey(homeMediaTabKey));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No flight context'), findsOneWidget);
      expect(find.text('LHR - MUC'), findsOneWidget);
      expect(find.text('View all'), findsNWidgets(2));
    },
  );

  testWidgets('supports preselecting Settings tab from constructor', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(initialTab: HomeRootTab.settings));
    await _pumpForInitialLoad(tester);

    expect(_findAppBarTitle('Settings'), findsOneWidget);
  });

  testWidgets('in-progress flight replaces the summary header as the hero', (
    tester,
  ) async {
    await GetIt.I.unregister<FlightRepository>();
    GetIt.I.registerSingleton<FlightRepository>(
      _FakeFlightRepository(
        flights: [
          _buildFlight(id: 'in-progress', status: FlightStatus.inProgress),
          _buildFlight(id: 'upcoming', status: FlightStatus.upcoming),
        ],
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding.profile.display_name', 'Stan');

    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);

    // The greeting/stats header yields to the in-progress hero card.
    expect(find.text('Hi Stan, your flight is in progress'), findsNothing);
    expect(find.text('Flight in progress'), findsOneWidget);
    expect(find.text('Upcoming flights (1)'), findsOneWidget);
    expect(find.byType(HomeFlightCard), findsNWidgets(2));
  });

  testWidgets(
    'flight card shows gate-to-gate duration estimate, not cruise-only time',
    (tester) async {
      await GetIt.I.unregister<FlightRepository>();
      GetIt.I.registerSingleton<FlightRepository>(
        _FakeFlightRepository(
          flights: [
            _buildFlight(id: 'upcoming', status: FlightStatus.upcoming),
          ],
        ),
      );

      await tester.pumpWidget(_testApp());
      await _pumpForInitialLoad(tester);

      // 1487.5 km: 105m cruise at 850 km/h + 55m taxi/climb/descent overhead.
      expect(find.text('~2h 40m'), findsOneWidget);
      expect(find.text('~1h 45m'), findsNothing);
    },
  );
}

Widget _testApp({HomeRootTab initialTab = HomeRootTab.flights}) {
  return TranslationProvider(
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(
            repository: SettingsRepository(),
            unitsRepository: MetricUnitsRepository(),
            onboardingRepository: OnboardingRepository(
              prefsStorage: UserFlightPrefsStorage(),
            ),
            airportsDatabase: AirportsDatabase.test(seedAirports: const []),
          )..load(),
        ),
        BlocProvider(
          create: (_) => SubscriptionCubit(
            repository: _FakeSubscriptionRepository(),
            flightUnlockRepository: _FakeFlightUnlockRepository(),
            analytics: const _FakeAppAnalytics(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HomeScreen(initialTab: initialTab),
      ),
    ),
  );
}

Finder _findAppBarTitle(String title) {
  return find.descendant(of: find.byType(AppBar), matching: find.text(title));
}

Future<void> _pumpForInitialLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

class _FakeFlightRepository implements FlightRepository {
  const _FakeFlightRepository({this.flights = const []});

  final List<Flight> flights;

  @override
  Future<List<Flight>> getAllFlights() async => flights;

  @override
  Future<Flight?> getFlightById(String flightId) async {
    for (final flight in flights) {
      if (flight.id == flightId) return flight;
    }
    return null;
  }

  @override
  Future<int> getTotalDownloadedMaps() async => 0;

  @override
  Future<int> getTotalFlights() async => flights.length;

  @override
  Future<int> getTotalMapSize() async => 0;

  @override
  Future<double> getTotalFlightDistanceKm() async {
    return flights.fold<double>(
      0,
      (sum, flight) => sum + flight.route.distanceInKm,
    );
  }

  @override
  Future<String> insertFlight(Flight flight) async => 'flight-id';

  @override
  Future<String> saveOrUpdateFlight(Flight flight) async => 'flight-id';

  @override
  Future<bool> updateFlightInfo({
    required String flightId,
    required FlightInfo info,
  }) async => true;

  @override
  Future<bool> updateFlightStatus({
    required String flightId,
    required FlightStatus status,
    DateTime? completedAt,
  }) async => true;
}

class _DelayedFlightRepository extends _FakeFlightRepository {
  const _DelayedFlightRepository(this.flightsCompleter);

  final Completer<List<Flight>> flightsCompleter;

  @override
  Future<List<Flight>> getAllFlights() => flightsCompleter.future;
}

class _FakeConnectivityChecker extends ConnectivityChecker {
  const _FakeConnectivityChecker();

  @override
  Future<bool> hasInternetConnectivity({
    Duration timeout = const Duration(seconds: 2),
  }) async => true;
}

Flight _buildFlight({required String id, required FlightStatus status}) {
  const departure = Airport(
    name: 'London Heathrow',
    city: 'London',
    countryCode: 'GB',
    latLon: LatLng(51.47, -0.45),
    iataCode: 'LHR',
    icaoCode: 'EGLL',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Munich Airport',
    city: 'Munich',
    countryCode: 'DE',
    latLon: LatLng(48.35, 11.79),
    iataCode: 'MUC',
    icaoCode: 'EDDM',
    wikipediaUrl: '',
  );
  const route = FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(51.47, -0.45)),
      FlightWaypoint(latLon: LatLng(48.35, 11.79)),
    ],
    corridor: [
      LatLng(51.47, -0.45),
      LatLng(48.35, -0.45),
      LatLng(48.35, 11.79),
    ],
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 1487.5,
      cruiseMinutes: 105,
    ),
  );

  return Flight(
    id: id,
    route: route,
    routeInsights: FlightInfo.empty.routeInsights,
    offlineContent: FlightInfo.empty.offlineContent,
    timestamp: FlightTimestamp(createdAt: DateTime(2026, 1, 1)),
    status: status,
  );
}

class _FakeDeleteFlightUseCase implements DeleteFlightUseCase {
  @override
  Future<bool> call(String flightId) async => true;
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository()
    : _currentStatus = SubscriptionStatus(
        isPro: false,
        entitlementId: 'pro',
        lastUpdatedAt: DateTime.now(),
      );

  final SubscriptionStatus _currentStatus;

  @override
  SubscriptionStatus get currentStatus => _currentStatus;

  @override
  Stream<SubscriptionStatus> get statusStream =>
      const Stream<SubscriptionStatus>.empty();

  @override
  Future<void> close() async {}

  @override
  Future<List<SubscriptionProduct>> getProducts() async =>
      const <SubscriptionProduct>[];

  @override
  Future<SubscriptionStatus> initialize() async => _currentStatus;

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded() async =>
      SubscriptionPaywallResult.notPresented;

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<SubscriptionStatus> purchasePackage({
    required String packageId,
  }) async => _currentStatus;

  @override
  Future<SubscriptionStatus> refresh() async => _currentStatus;

  @override
  Future<SubscriptionStatus> restorePurchases() async => _currentStatus;
}

class _FakeFlightUnlockRepository implements FlightUnlockRepository {
  @override
  Stream<int> get balanceStream => const Stream<int>.empty();

  @override
  int get currentUnusedUnlockCount => 0;

  @override
  Future<void> close() async {}

  @override
  Future<int> consumeUnlock() async => 0;

  @override
  Future<FlightUnlockProduct?> getUnlockProduct() async => null;

  @override
  Future<int> initialize() async => 0;

  @override
  Future<FlightUnlockPurchaseResult> purchaseUnlock() async =>
      const FlightUnlockPurchaseResult.cancelled();

  @override
  Future<int> restoreUnlock() async => 0;
}

class _FakeAppAnalytics implements AppAnalytics {
  const _FakeAppAnalytics();

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

class _FakeSkyCameraMediaRepository extends SkyCameraMediaRepository {
  _FakeSkyCameraMediaRepository({
    List<SkyCameraMediaItem> captures = const <SkyCameraMediaItem>[],
  }) : _captures = List<SkyCameraMediaItem>.of(captures),
       super.forTest();

  final List<SkyCameraMediaItem> _captures;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> watch() => _changes.stream;

  @override
  Future<List<SkyCameraMediaItem>> getCaptures() async =>
      List<SkyCameraMediaItem>.of(_captures);

  @override
  Future<void> addCapture(SkyCameraMediaItem capture) async {
    _captures.removeWhere((item) => item.id == capture.id);
    _captures.insert(0, capture);
    _changes.add(null);
  }

  @override
  Future<void> deleteCaptureIds(Iterable<String> captureIds) async {
    final ids = captureIds.toSet();
    _captures.removeWhere((item) => ids.contains(item.id));
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

SkyCameraMediaItem _buildMediaItem({
  required String id,
  required DateTime capturedAt,
  String? flightId,
  String routeLabel = 'Placeholder',
  String originCode = '',
  String destinationCode = '',
}) {
  return SkyCameraMediaItem(
    id: id,
    capturedAt: capturedAt,
    mediaType: SkyCameraMediaType.photo,
    sourcePath: '/tmp/$id.jpg',
    flightId: flightId,
    snapshot: SkyCameraOverlaySnapshot(
      timestamp: capturedAt,
      routeLabel: routeLabel,
      originCode: originCode,
      destinationCode: destinationCode,
      originCountryCode: 'GB',
      destinationCountryCode: 'ES',
      contextLabel: 'Context',
      mapStatePlaceholder: 'Map',
      hasLiveLocation: false,
      latitude: null,
      longitude: null,
      headingDegrees: null,
      altitudeMeters: null,
      speedMetersPerSecond: null,
    ),
    renditions: [
      SkyCameraMediaRendition(
        id: 'default',
        skinId: 'flymap_default_v1',
        mediaType: SkyCameraMediaType.photo,
        path: '/tmp/$id-overlay.png',
        previewImagePath: '/tmp/$id-overlay.png',
      ),
    ],
    trackPoints: const [],
    previewImagePath: '/tmp/$id-overlay.png',
    selectedRenditionId: 'default',
  );
}

class _FakeFlymapSkyCameraSessionFactory extends FlymapSkyCameraSessionFactory {
  _FakeFlymapSkyCameraSessionFactory({
    required SkyCameraMediaRepository mediaRepository,
    super.flightRepository = const _FakeFlightRepository(),
  }) : super(
         exportService: FlymapSkyCameraExportService(
           flightRepository: flightRepository,
           mediaRepository: mediaRepository,
         ),
         shareService: FlymapSkyCameraShareService(
           analytics: const _FakeAppAnalytics(),
         ),
         analytics: const _FakeAppAnalytics(),
         locationService: AppLocationService(
           client: const _FakeAppLocationClient(),
         ),
       );

  String? createdForFlightId;

  @override
  FlymapSkyCameraSession create({
    required FlymapSkyCameraPlaceholderCopy placeholderCopy,
    bool recordAudioEnabled = false,
  }) {
    return _createSession(placeholderCopy);
  }

  @override
  FlymapSkyCameraSession createForFlight({
    required FlymapSkyCameraPlaceholderCopy placeholderCopy,
    required String flightId,
    bool recordAudioEnabled = false,
  }) {
    createdForFlightId = flightId;
    return _createSession(placeholderCopy);
  }

  FlymapSkyCameraSession _createSession(
    FlymapSkyCameraPlaceholderCopy placeholderCopy,
  ) {
    return FlymapSkyCameraSession(
      driver: _FakeSkyCameraDriver(),
      snapshotSource: _FakeSkyCameraSnapshotSource(
        placeholderCopy: placeholderCopy,
      ),
      exportService: _NoopSkyCameraExportService(),
      shareService: _NoopSkyCameraShareService(),
      observer: const _NoopSkyCameraObserver(),
    );
  }
}

class _FakeSkyCameraDriver implements SkyCameraDriver {
  bool _isInitialized = false;

  @override
  SkyCameraFlashState get flashState => SkyCameraFlashState.off;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Widget buildPreview() {
    return const ColoredBox(
      key: Key('test.sky_camera.preview'),
      color: Colors.black,
      child: SizedBox.expand(),
    );
  }

  @override
  Future<SkyCameraCapturedPhoto> capturePhoto() async {
    return SkyCameraCapturedPhoto(
      bytes: Uint8List(0),
      fileExtension: 'jpg',
      capturedAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<void> onAppLifecycleStateChanged(AppLifecycleState state) async {}

  @override
  Future<void> setFocusPoint(Offset normalizedPoint) async {}

  @override
  Future<SkyCameraZoomBounds> getZoomBounds() async {
    return const SkyCameraZoomBounds(min: 1.0, max: 4.0);
  }

  @override
  Future<void> setZoomLevel(double zoomLevel) async {}

  @override
  Future<void> toggleFlash() async {}

  @override
  bool get isAudioEnabled => false;

  @override
  Future<void> setAudioEnabled(bool enabled) async {}

  @override
  bool get isRecordingVideo => false;

  @override
  Future<void> startVideoRecording() async {}

  @override
  Future<SkyCameraCapturedVideo> stopVideoRecording() async {
    return SkyCameraCapturedVideo(
      filePath: '/tmp/test.mp4',
      fileExtension: 'mp4',
      capturedAt: DateTime(2026, 1, 1),
      duration: const Duration(seconds: 1),
    );
  }
}

class _FakeAppLocationClient implements AppLocationClient {
  const _FakeAppLocationClient();

  @override
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.denied;
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    return const Stream<Position>.empty();
  }

  @override
  Future<Position> getCurrentPosition({
    required LocationAccuracy accuracy,
  }) async {
    throw UnsupportedError('No test location');
  }

  @override
  Future<bool> isLocationServiceEnabled() async => false;

  @override
  Future<LocationPermission> requestPermission() async {
    return LocationPermission.denied;
  }
}

class _FakeSkyCameraSnapshotSource implements SkyCameraOverlaySnapshotSource {
  const _FakeSkyCameraSnapshotSource({required this.placeholderCopy});

  final FlymapSkyCameraPlaceholderCopy placeholderCopy;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> start() async {}

  @override
  Stream<SkyCameraOverlaySnapshot> watch() {
    return Stream<SkyCameraOverlaySnapshot>.value(
      SkyCameraOverlaySnapshot(
        timestamp: DateTime(2026, 1, 1, 12, 0),
        routeLabel: placeholderCopy.routeLabel,
        originCode: placeholderCopy.originCode,
        destinationCode: placeholderCopy.destinationCode,
        originCountryCode: placeholderCopy.originCountryCode,
        destinationCountryCode: placeholderCopy.destinationCountryCode,
        contextLabel: placeholderCopy.contextLabel,
        mapStatePlaceholder: placeholderCopy.mapPlaceholder,
        hasLiveLocation: false,
        latitude: null,
        longitude: null,
        headingDegrees: null,
        altitudeMeters: null,
        speedMetersPerSecond: null,
      ),
    );
  }
}

class _NoopSkyCameraExportService implements SkyCameraExportService {
  @override
  Future<SkyCameraSavedCapture> saveCapture({
    required SkyCameraCapturedPhoto originalPhoto,
    required SkyCameraOverlaySnapshot snapshot,
    required List<int> overlayBytes,
  }) async {
    return const SkyCameraSavedCapture(
      id: 'capture-1',
      originalPath: '/tmp/original.jpg',
      overlayPath: '/tmp/overlay.png',
    );
  }

  @override
  Future<SkyCameraSavedCapture> saveVideoCapture({
    required SkyCameraCapturedVideo video,
    required SkyCameraOverlaySnapshot snapshot,
    required List<SkyCameraVideoTrackSample> track,
  }) async {
    return const SkyCameraSavedCapture(
      id: 'capture-1',
      originalPath: '/tmp/original.mp4',
      overlayPath: '/tmp/poster.png',
      isVideo: true,
    );
  }
}

class _NoopSkyCameraShareService implements SkyCameraShareService {
  @override
  Future<void> shareCapture({
    required SkyCameraSavedCapture capture,
    required Rect sharePositionOrigin,
  }) async {}
}

class _NoopSkyCameraObserver implements SkyCameraObserver {
  const _NoopSkyCameraObserver();

  @override
  Future<void> onOpened({required SkyCameraOverlaySnapshot snapshot}) async {}

  @override
  Future<void> onPhotoCaptured({
    required SkyCameraOverlaySnapshot snapshot,
  }) async {}

  @override
  Future<void> onVideoCaptured({
    required SkyCameraOverlaySnapshot snapshot,
    required Duration duration,
  }) async {}
}

class _FakeRatePromptPolicyService implements RatePromptPolicyService {
  const _FakeRatePromptPolicyService();

  @override
  Future<void> recordAccepted() async {}

  @override
  Future<void> recordDeclined() async {}

  @override
  Future<void> recordDismissed() async {}

  @override
  Future<void> recordReviewRequested() async {}

  @override
  Future<void> recordAppShared() async {}

  @override
  Future<void> registerTrigger(RatePromptTrigger trigger) async {}

  @override
  Future<RatePromptState?> getPromptState() async => null;
}

class _FakeLearnRepository implements LearnRepository {
  _FakeLearnRepository() {
    _categories = [
      LearnCategory(
        id: 'free_cat',
        title: 'Free Cat',
        description: 'Free description',
        imageAssetPath: 'assets/images/learn/categories/free_cat.webp',
        articles: const [
          LearnArticleMeta(
            id: 'f1',
            title: 'Free One',
            categoryId: 'free_cat',
            access: LearnAccess.free,
          ),
        ],
      ),
      LearnCategory(
        id: 'pro_cat',
        title: 'Pro Cat',
        description: 'Pro description',
        imageAssetPath: 'assets/images/learn/categories/pro_cat.webp',
        articles: const [
          LearnArticleMeta(
            id: 'p1',
            title: 'Pro One',
            categoryId: 'pro_cat',
            access: LearnAccess.pro,
          ),
        ],
      ),
    ];
  }

  late final List<LearnCategory> _categories;

  @override
  bool canOpenArticle({
    required LearnAccess articleAccess,
    required bool isProUser,
  }) {
    return articleAccess == LearnAccess.free || isProUser;
  }

  @override
  Future<LearnArticleContent> getArticleContent({
    required String articleId,
  }) async {
    final article = _categories
        .expand((category) => category.articles)
        .firstWhere((item) => item.id == articleId);
    return LearnArticleContent(
      id: article.id,
      title: article.title,
      categoryId: article.categoryId,
      markdown: '# ${article.title}',
    );
  }

  @override
  Future<List<LearnArticleMeta>> getArticles({
    required String categoryId,
  }) async {
    return _categories
        .firstWhere((category) => category.id == categoryId)
        .articles;
  }

  @override
  Future<List<LearnCategory>> getCategories() async {
    return _categories;
  }
}

class _FakeGeoQuizRepository implements GeoQuizRepository {
  const _FakeGeoQuizRepository();

  @override
  Future<List<GeoQuizSummary>> getQuizzes({
    required String collectionId,
  }) async {
    return switch (collectionId) {
      'countries' => const [
        GeoQuizSummary(
          id: 'countries_africa',
          collectionId: 'countries',
          title: 'Africa',
          subtitle: 'Countries',
          totalCount: 1,
        ),
      ],
      'geography' => const [
        GeoQuizSummary(
          id: 'geography_seas',
          collectionId: 'geography',
          title: 'Seas',
          subtitle: 'Seas',
          totalCount: 0,
          iconName: 'waves',
        ),
      ],
      _ => const [],
    };
  }

  @override
  Future<List<GeoQuizRegion>> getRegions({required String quizId}) async {
    return const [
      GeoQuizRegion(id: 'AO', countryCode: 'AO', names: {'en': 'Angola'}),
    ];
  }

  @override
  Future<String?> getRegionDescription({
    required String quizId,
    required String regionId,
    required String languageCode,
  }) async {
    return null;
  }
}

class _InMemoryLearnArticleProgressRepository
    implements LearnArticleProgressRepository {
  final Map<String, LearnArticleProgress> _state =
      <String, LearnArticleProgress>{};

  @override
  Future<Map<String, LearnArticleProgress>> getByArticleIds(
    Iterable<String> articleIds,
  ) async {
    return <String, LearnArticleProgress>{
      for (final id in articleIds) id: _state[id] ?? LearnArticleProgress.empty,
    };
  }

  @override
  Future<LearnArticleProgress> markSeen(String articleId) async {
    final updated = (_state[articleId] ?? LearnArticleProgress.empty).copyWith(
      isSeen: true,
    );
    _state[articleId] = updated;
    return updated;
  }

  @override
  Future<LearnArticleProgress> toggleFavorite(String articleId) async {
    final current = _state[articleId] ?? LearnArticleProgress.empty;
    final updated = current.copyWith(isFavorite: !current.isFavorite);
    _state[articleId] = updated;
    return updated;
  }
}
