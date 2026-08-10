import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_operational_data.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/entity/user_profile.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/domain/entity/route_poi.dart';
import 'package:flymap/domain/entity/flight_poi_type.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/weather_attribution.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/entity/route_overview.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/domain/entity/route_timeline.dart';
import 'package:flymap/domain/entity/user_flight_prefs.dart';
import 'package:flymap/domain/entity/wiki_article_candidate.dart';
import 'package:flymap/domain/policy/poi_limits_policy.dart';
import 'package:flymap/domain/provider/weather_forecast_provider.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/repository/user_flight_prefs_repository.dart';
import 'package:flymap/subscription/flight_unlock_product.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/domain/usecase/download_map_use_case.dart';
import 'package:flymap/domain/usecase/download_region_wiki_articles_use_case.dart';
import 'package:flymap/domain/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/domain/usecase/get_wiki_articles_use_case.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';
import 'package:flymap/domain/usecase/build_flight_route_preview_use_case.dart';
import 'package:flymap/domain/usecase/get_route_overview_use_case.dart';
import 'package:flymap/domain/usecase/fetch_flight_weather_use_case.dart';
import 'package:flymap/repository/flight_search_repository.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('FlightPreviewCubit wiki selection', () {
    late _FakeDownloadWikipediaArticlesUseCase wikiDownloadUseCase;
    late _FakeDownloadRegionWikiArticlesUseCase regionWikiDownloadUseCase;
    late _FakeDownloadMapUseCase mapUseCase;
    late _FakeConnectivityChecker connectivityChecker;
    late _FakeSubscriptionRepository subscriptionRepository;
    late _FakeFlightUnlockRepository flightUnlockRepository;
    late _FakeGetRouteOverviewUseCase routeOverviewUseCase;
    late _TestFlightPreviewCubit cubit;

    setUp(() {
      wikiDownloadUseCase = _FakeDownloadWikipediaArticlesUseCase();
      regionWikiDownloadUseCase = _FakeDownloadRegionWikiArticlesUseCase();
      mapUseCase = _FakeDownloadMapUseCase();
      connectivityChecker = _FakeConnectivityChecker();
      subscriptionRepository = _FakeSubscriptionRepository();
      flightUnlockRepository = _FakeFlightUnlockRepository();
      final route = _route();
      routeOverviewUseCase = _FakeGetRouteOverviewUseCase(
        routeOverview: _routeOverviewFor(route),
      );
      cubit = _TestFlightPreviewCubit(
        departure: route.departure,
        arrival: route.arrival,
        connectivityChecker: connectivityChecker,
        getRouteOverviewUseCase: routeOverviewUseCase,
        buildFlightRoutePreviewUseCase: _FakeBuildFlightRoutePreviewUseCase(),
        downloadMapUseCase: mapUseCase,
        downloadRegionWikiArticlesUseCase: regionWikiDownloadUseCase,
        downloadWikipediaArticlesUseCase: wikiDownloadUseCase,
        getWikiArticlesUseCase: _FakeGetWikiArticlesUseCase(),
        userFlightPrefsRepository: _FakeUserFlightPrefsRepository(),
        flightRepository: _FakeFlightRepository(),
        subscriptionRepository: subscriptionRepository,
        flightUnlockRepository: flightUnlockRepository,
        deleteFlightUseCase: _FakeDeleteFlightUseCase(),
        analytics: _FakeAppAnalytics(),
        crashlytics: _FakeAppCrashlytics(),
      );
      cubit.setStateForTest(
        cubit.state.copyWith(
          step: CreateFlightStep.wikipediaArticles,
          articleCandidates: _candidates(4),
          selectedArticleUrls: const [],
          flightRoute: _route(),
        ),
      );
    });

    tearDown(() async {
      await cubit.close();
      await flightUnlockRepository.close();
    });

    test('free user can select more than 3 articles in UI state', () {
      cubit.toggleWikiArticleSelection(_url(1));
      cubit.toggleWikiArticleSelection(_url(2));
      cubit.toggleWikiArticleSelection(_url(3));
      cubit.toggleWikiArticleSelection(_url(4));

      expect(cubit.state.selectedArticleUrls, [
        _url(1),
        _url(2),
        _url(3),
        _url(4),
      ]);
    });

    test('user can deselect and select a different article', () {
      cubit.toggleWikiArticleSelection(_url(1));
      cubit.toggleWikiArticleSelection(_url(2));
      cubit.toggleWikiArticleSelection(_url(3));
      cubit.toggleWikiArticleSelection(_url(2)); // deselect
      cubit.toggleWikiArticleSelection(_url(4)); // select new one

      expect(cubit.state.selectedArticleUrls, [_url(1), _url(3), _url(4)]);
    });

    test('select all selects all candidates', () {
      cubit.toggleAllWikiArticleSelections();
      expect(cubit.state.selectedArticleUrls, _candidates(4).map((e) => e.url));
    });

    test(
      'startDownload as free never passes more than 3 urls to article downloader',
      () async {
        subscriptionRepository.isPro = false;
        cubit.setStateForTest(
          cubit.state.copyWith(
            selectedArticleUrls: [_url(1), _url(2), _url(3), _url(4)],
          ),
        );

        await cubit.startDownload();

        expect(wikiDownloadUseCase.lastRequestedUrls, [
          _url(1),
          _url(2),
          _url(3),
        ]);
        expect(cubit.state.selectedArticleUrls, [_url(1), _url(2), _url(3)]);
      },
    );

    test(
      'startDownload as pro passes all selected urls to article downloader',
      () async {
        subscriptionRepository.isPro = true;
        cubit.setStateForTest(
          cubit.state.copyWith(
            selectedArticleUrls: [_url(1), _url(2), _url(3), _url(4)],
          ),
        );

        await cubit.startDownload();

        expect(wikiDownloadUseCase.lastRequestedUrls, [
          _url(1),
          _url(2),
          _url(3),
          _url(4),
        ]);
      },
    );

    test(
      'startDownload with pending unlock uses pro tier and consumes balance',
      () async {
        subscriptionRepository.isPro = false;
        flightUnlockRepository.unusedCount = 1;
        cubit.setStateForTest(
          cubit.state.copyWith(
            selectedArticleUrls: [_url(1), _url(2), _url(3), _url(4)],
            flightRoute: _route(),
            hasPendingFlightUnlock: true,
          ),
        );

        await cubit.startDownload();

        expect(wikiDownloadUseCase.lastRequestedUrls, [
          _url(1),
          _url(2),
          _url(3),
          _url(4),
        ]);
        expect(mapUseCase.lastFlightAccessTier, Flight.accessTierPro);
        expect(flightUnlockRepository.consumeCount, 1);
        expect(cubit.state.hasPendingFlightUnlock, isFalse);
      },
    );

    test('startDownload passes z10 for free short route', () async {
      subscriptionRepository.isPro = false;
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          flightRoute: _route(),
        ),
      );

      await cubit.startDownload();

      expect(mapUseCase.lastMaxZoom, 10);
    });

    test('startDownload passes z9 for free long route', () async {
      subscriptionRepository.isPro = false;
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          flightRoute: _longRoute(),
        ),
      );

      await cubit.startDownload();

      expect(mapUseCase.lastMaxZoom, 9);
    });

    test('startDownload passes z11 for pro short route', () async {
      subscriptionRepository.isPro = true;
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          flightRoute: _route(),
        ),
      );

      await cubit.startDownload();

      expect(mapUseCase.lastMaxZoom, 11);
    });

    test('startDownload passes z10 for pro long route', () async {
      subscriptionRepository.isPro = true;
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          flightRoute: _longRoute(),
        ),
      );

      await cubit.startDownload();

      expect(mapUseCase.lastMaxZoom, 10);
    });

    test('offline overview shows error state flag', () async {
      connectivityChecker.hasInternet = false;
      cubit.setStateForTest(
        cubit.state.copyWith(step: CreateFlightStep.overview),
      );
      await cubit.preparePreview();

      expect(cubit.state.step, CreateFlightStep.overview);
      expect(cubit.state.isPreviewLoading, isFalse);
      expect(cubit.state.hasInternetForMapPreview, isFalse);
    });

    test(
      'long-haul approximate route shows blocking warning in overview',
      () async {
        final longHaulRoute = _warningThresholdRoute();
        routeOverviewUseCase.routeOverview = _routeOverviewFor(longHaulRoute);
        cubit.setStateForTest(FlightPreviewState.initial());

        await cubit.preparePreview();

        expect(cubit.state.step, CreateFlightStep.overview);
        expect(cubit.state.flightRoute, longHaulRoute);
        expect(cubit.state.overviewWarningTitle, 'This is approximate route');
        expect(
          cubit.state.overviewWarningMessage,
          'Approximate routes may be inaccurate for long-haul flights. Use a real route with a flight number instead.',
        );
      },
    );

    test('ultra long-haul approximate route is blocked', () async {
      final ultraLongHaulRoute = _unsupportedThresholdRoute();
      routeOverviewUseCase.routeOverview = _routeOverviewFor(
        ultraLongHaulRoute,
      );
      cubit.setStateForTest(FlightPreviewState.initial());

      await cubit.preparePreview();

      expect(cubit.state.step, CreateFlightStep.routeNotSupported);
      expect(cubit.state.flightRoute, ultraLongHaulRoute);
      expect(
        cubit.state.errorMessage,
        'Approximate routes are not supported for ultra long-haul flights. Use a real route with a flight number instead.',
      );
      expect(cubit.state.overviewWarningTitle, isNull);
      expect(cubit.state.overviewWarningMessage, isNull);
    });

    test('refreshPoisForPro applies cached pro POI slice', () async {
      final pois = _routePoiSummaries(80);
      cubit.setStateForTest(
        cubit.state.copyWith(
          allRoutePois: pois,
          flightInfo: cubit.state.flightInfo.copyWith(
            poi: pois.take(10).toList(),
          ),
          flightRoute: _route(),
        ),
      );

      await cubit.refreshPoisForPro();

      expect(cubit.state.flightInfo.poi.length, 80);
    });

    test('preparePreview with pending unlock applies pro POI slice', () async {
      // More candidates than the pro cap so the tier slice actually binds.
      final pois = _routePoiSummaries(PoiLimitsPolicy.proMaxPois + 50);
      routeOverviewUseCase.routeOverview = _routeOverviewFor(
        _route(),
        topPois: pois,
      );
      cubit.setStateForTest(
        FlightPreviewState.initial().copyWith(hasPendingFlightUnlock: true),
      );

      await cubit.preparePreview();

      expect(
        cubit.state.flightInfo.poi.length,
        PoiLimitsPolicy.maxPoisForTier(isProUser: true),
      );
    });

    test(
      'preparePreview prefetches weather for an existing Pro user',
      () async {
        subscriptionRepository.isPro = true;
        final weatherProvider = _CountingWeatherForecastProvider();
        final weatherCubit = _TestFlightPreviewCubit(
          departure: _route().departure,
          arrival: _route().arrival,
          schedule: _tomorrowAtNoon(),
          fetchFlightWeatherUseCase: FetchFlightWeatherUseCase(
            provider: weatherProvider,
          ),
          connectivityChecker: connectivityChecker,
          getRouteOverviewUseCase: routeOverviewUseCase,
          buildFlightRoutePreviewUseCase: _FakeBuildFlightRoutePreviewUseCase(),
          downloadMapUseCase: mapUseCase,
          downloadRegionWikiArticlesUseCase: regionWikiDownloadUseCase,
          downloadWikipediaArticlesUseCase: wikiDownloadUseCase,
          getWikiArticlesUseCase: _FakeGetWikiArticlesUseCase(),
          userFlightPrefsRepository: _FakeUserFlightPrefsRepository(),
          flightRepository: _FakeFlightRepository(),
          subscriptionRepository: subscriptionRepository,
          flightUnlockRepository: flightUnlockRepository,
          deleteFlightUseCase: _FakeDeleteFlightUseCase(),
          analytics: _FakeAppAnalytics(),
          crashlytics: _FakeAppCrashlytics(),
        );
        addTearDown(weatherCubit.close);

        await weatherCubit.preparePreview();
        await Future<void>.delayed(Duration.zero);

        expect(weatherProvider.calls, 1);
        expect(weatherCubit.state.flightWeather, isNotNull);
        expect(weatherCubit.state.step, CreateFlightStep.overview);
      },
    );

    test('preparePreview prefetches weather for an unlocked flight', () async {
      subscriptionRepository.isPro = false;
      final weatherProvider = _CountingWeatherForecastProvider();
      final weatherCubit = _TestFlightPreviewCubit(
        departure: _route().departure,
        arrival: _route().arrival,
        schedule: _tomorrowAtNoon(),
        hasPendingFlightUnlock: true,
        fetchFlightWeatherUseCase: FetchFlightWeatherUseCase(
          provider: weatherProvider,
        ),
        connectivityChecker: connectivityChecker,
        getRouteOverviewUseCase: routeOverviewUseCase,
        buildFlightRoutePreviewUseCase: _FakeBuildFlightRoutePreviewUseCase(),
        downloadMapUseCase: mapUseCase,
        downloadRegionWikiArticlesUseCase: regionWikiDownloadUseCase,
        downloadWikipediaArticlesUseCase: wikiDownloadUseCase,
        getWikiArticlesUseCase: _FakeGetWikiArticlesUseCase(),
        userFlightPrefsRepository: _FakeUserFlightPrefsRepository(),
        flightRepository: _FakeFlightRepository(),
        subscriptionRepository: subscriptionRepository,
        flightUnlockRepository: flightUnlockRepository,
        deleteFlightUseCase: _FakeDeleteFlightUseCase(),
        analytics: _FakeAppAnalytics(),
        crashlytics: _FakeAppCrashlytics(),
      );
      addTearDown(weatherCubit.close);

      await weatherCubit.preparePreview();
      await Future<void>.delayed(Duration.zero);

      expect(weatherProvider.calls, 1);
      expect(weatherCubit.state.flightWeather, isNotNull);
    });

    test(
      'real flight without a recorded track falls back to a generated route',
      () async {
        final route = _route();
        final fallbackCubit = _TestFlightPreviewCubit(
          departure: route.departure,
          arrival: route.arrival,
          flightNumber: 'XX123',
          airlineCodeHint: 'XX',
          airlineNameHint: 'Example Air',
          connectivityChecker: connectivityChecker,
          getRouteOverviewUseCase: routeOverviewUseCase,
          // FR24 has never recorded the route: the preview callable 404s.
          buildFlightRoutePreviewUseCase: _FakeBuildFlightRoutePreviewUseCase(
            error: _TestFirebaseFunctionsException(
              code: 'not-found',
              message: 'No route track found for this flight',
            ),
          ),
          downloadMapUseCase: mapUseCase,
          downloadRegionWikiArticlesUseCase: regionWikiDownloadUseCase,
          downloadWikipediaArticlesUseCase: wikiDownloadUseCase,
          getWikiArticlesUseCase: _FakeGetWikiArticlesUseCase(),
          userFlightPrefsRepository: _FakeUserFlightPrefsRepository(),
          flightRepository: _FakeFlightRepository(),
          subscriptionRepository: subscriptionRepository,
          flightUnlockRepository: flightUnlockRepository,
          deleteFlightUseCase: _FakeDeleteFlightUseCase(),
          analytics: _FakeAppAnalytics(),
          crashlytics: _FakeAppCrashlytics(),
        );
        addTearDown(fallbackCubit.close);

        await fallbackCubit.preparePreview();

        final state = fallbackCubit.state;
        // No dead end: the generated route (approximate pipeline) loads...
        expect(state.errorMessage, isNull);
        expect(state.flightRoute, isNotNull);
        // ...and the flight identity survives the fallback.
        expect(state.flightOperationalData?.flightNumber, 'XX123');
        expect(state.flightOperationalData?.airlineCode, 'XX');
        expect(state.flightOperationalData?.airlineName, 'Example Air');
      },
    );

    test(
      'back from wiki steps through weather and preserves pending unlock',
      () async {
        final pois = _routePoiSummaries(120);
        cubit.setStateForTest(
          cubit.state.copyWith(
            step: CreateFlightStep.wikipediaArticles,
            allRoutePois: pois,
            flightInfo: cubit.state.flightInfo.copyWith(
              poi: pois.take(10).toList(growable: false),
            ),
            hasPendingFlightUnlock: true,
          ),
        );

        final backFromWiki = await cubit.handleBackAction();
        expect(backFromWiki, isFalse);
        expect(cubit.state.step, CreateFlightStep.weather);

        final backFromWeather = await cubit.handleBackAction();
        expect(backFromWeather, isFalse);
        expect(cubit.state.step, CreateFlightStep.overview);
        expect(cubit.state.hasPendingFlightUnlock, isTrue);
      },
    );

    test('pro tier POI cap uses policy max', () async {
      subscriptionRepository.isPro = true;
      final pois = _routePoiSummaries(260);
      cubit.setStateForTest(
        cubit.state.copyWith(
          allRoutePois: pois,
          flightInfo: cubit.state.flightInfo.copyWith(
            poi: pois.take(10).toList(growable: false),
          ),
        ),
      );

      await cubit.refreshPoisForPro();

      expect(cubit.state.flightInfo.poi.length, PoiLimitsPolicy.proMaxPois);
    });

    test('region wiki resolution uses the current app language', () async {
      await LocaleSettings.setLocale(AppLocale.es);
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
      subscriptionRepository.isPro = true;
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          flightRoute: _route(),
          flightInfo: cubit.state.flightInfo.copyWith(
            routeRegions: const [
              RouteRegion(
                qid: 'Q84',
                name: 'London',
                regionType: RouteRegionType.region,
                pathFirstEncounterKm: 0,
                pathLengthInsideKm: 42,
                geometry: RouteRegionGeometry(type: 'Polygon', geoJson: {}),
              ),
            ],
          ),
        ),
      );

      await cubit.startDownload();

      expect(regionWikiDownloadUseCase.lastPreferredLanguageCode, 'es');
    });

    test('free user downloads only ungated regions', () async {
      subscriptionRepository.isPro = false;
      const regions = [
        RouteRegion(
          qid: 'Q3',
          name: 'Region 3',
          regionType: RouteRegionType.region,
          pathFirstEncounterKm: 300,
          pathLengthInsideKm: 12,
          geometry: RouteRegionGeometry(type: 'Polygon', geoJson: {}),
        ),
        RouteRegion(
          qid: 'Q1',
          name: 'Region 1',
          regionType: RouteRegionType.region,
          pathFirstEncounterKm: 100,
          pathLengthInsideKm: 12,
          geometry: RouteRegionGeometry(type: 'Polygon', geoJson: {}),
        ),
        RouteRegion(
          qid: 'Q5',
          name: 'Region 5',
          regionType: RouteRegionType.region,
          pathFirstEncounterKm: 500,
          pathLengthInsideKm: 12,
          geometry: RouteRegionGeometry(type: 'Polygon', geoJson: {}),
        ),
        RouteRegion(
          qid: 'Q2',
          name: 'Region 2',
          regionType: RouteRegionType.region,
          pathFirstEncounterKm: 200,
          pathLengthInsideKm: 12,
          geometry: RouteRegionGeometry(type: 'Polygon', geoJson: {}),
        ),
        RouteRegion(
          qid: 'Q4',
          name: 'Region 4',
          regionType: RouteRegionType.region,
          pathFirstEncounterKm: 400,
          pathLengthInsideKm: 12,
          geometry: RouteRegionGeometry(type: 'Polygon', geoJson: {}),
        ),
      ];
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          flightRoute: _route(),
          flightInfo: cubit.state.flightInfo.copyWith(routeRegions: regions),
        ),
      );

      await cubit.startDownload();

      expect(regionWikiDownloadUseCase.lastRequestedRegionQids, {'Q1', 'Q2'});
    });
  });
}

String _url(int i) => 'https://en.wikipedia.org/wiki/Article_$i';

List<WikiArticleCandidate> _candidates(int count) {
  return List.generate(
    count,
    (index) => WikiArticleCandidate(
      url: _url(index + 1),
      title: 'Article ${index + 1}',
      languageCode: 'en',
    ),
  );
}

FlightRoute _route() {
  const departure = Airport(
    name: 'A',
    city: 'A',
    countryCode: 'US',
    latLon: LatLng(10, 10),
    iataCode: 'AAA',
    icaoCode: 'AAAA',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'B',
    city: 'B',
    countryCode: 'US',
    latLon: LatLng(20, 20),
    iataCode: 'BBB',
    icaoCode: 'BBBB',
    wikipediaUrl: '',
  );
  return FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(10, 10)),
      FlightWaypoint(latLon: LatLng(20, 20)),
    ],
    corridor: _corridorBetween(departure.latLon, arrival.latLon),
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 1500,
      cruiseMinutes: 105,
    ),
  );
}

FlightRoute _longRoute() {
  const departure = Airport(
    name: 'C',
    city: 'C',
    countryCode: 'US',
    latLon: LatLng(10, 10),
    iataCode: 'CCC',
    icaoCode: 'CCCC',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'D',
    city: 'D',
    countryCode: 'US',
    latLon: LatLng(35, 35),
    iataCode: 'DDD',
    icaoCode: 'DDDD',
    wikipediaUrl: '',
  );
  return FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(10, 10)),
      FlightWaypoint(latLon: LatLng(35, 35)),
    ],
    corridor: _corridorBetween(departure.latLon, arrival.latLon),
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 3500,
      cruiseMinutes: 245,
    ),
  );
}

FlightRoute _warningThresholdRoute() {
  const departure = Airport(
    name: 'San Francisco International Airport',
    city: 'San Francisco',
    countryCode: 'US',
    latLon: LatLng(37.6213, -122.3790),
    iataCode: 'SFO',
    icaoCode: 'KSFO',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Heathrow Airport',
    city: 'London',
    countryCode: 'GB',
    latLon: LatLng(51.4700, -0.4543),
    iataCode: 'LHR',
    icaoCode: 'EGLL',
    wikipediaUrl: '',
  );
  return FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: departure.latLon),
      FlightWaypoint(latLon: arrival.latLon),
    ],
    corridor: _corridorBetween(departure.latLon, arrival.latLon),
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 8600,
      cruiseMinutes: 605,
    ),
  );
}

FlightRoute _unsupportedThresholdRoute() {
  const departure = Airport(
    name: 'John F. Kennedy International Airport',
    city: 'New York',
    countryCode: 'US',
    latLon: LatLng(40.6413, -73.7781),
    iataCode: 'JFK',
    icaoCode: 'KJFK',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Singapore Changi Airport',
    city: 'Singapore',
    countryCode: 'SG',
    latLon: LatLng(1.3644, 103.9915),
    iataCode: 'SIN',
    icaoCode: 'WSSS',
    wikipediaUrl: '',
  );
  return FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: departure.latLon),
      FlightWaypoint(latLon: arrival.latLon),
    ],
    corridor: _corridorBetween(departure.latLon, arrival.latLon),
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 11000,
      cruiseMinutes: 775,
    ),
  );
}

List<LatLng> _corridorBetween(LatLng departure, LatLng arrival) {
  return [
    departure,
    LatLng(
      (departure.latitude + arrival.latitude) / 2,
      (departure.longitude + arrival.longitude) / 2,
    ),
    arrival,
  ];
}

RouteOverview _routeOverviewFor(
  FlightRoute route, {
  List<RoutePoiSummary> topPois = const [],
}) {
  return RouteOverview(
    route: route,
    topPois: topPois,
    flightInfo: null,
    timeline: const RouteTimeline(
      regions: [
        RouteRegion(
          qid: 'Q1',
          name: 'France',
          regionType: RouteRegionType.country,
          pathFirstEncounterKm: 100,
          pathLengthInsideKm: 120,
          geometry: RouteRegionGeometry(
            type: 'Polygon',
            geoJson: {
              'type': 'Polygon',
              'coordinates': [
                [
                  [2.0, 45.0],
                  [2.1, 45.0],
                  [2.1, 45.1],
                  [2.0, 45.1],
                  [2.0, 45.0],
                ],
              ],
            },
          ),
        ),
      ],
      blockMinutes: 95,
      cruiseSpeedKmh: 850,
    ),
  );
}

List<RoutePoiSummary> _routePoiSummaries(int count) {
  return List.generate(
    count,
    (i) => RoutePoiSummary(
      poi: RoutePoi(
        qid: 'Q${1000 + i}',
        name: 'POI ${i + 1}',
        latLon: LatLng(10 + i / 10, 10 + i / 10),
        type: FlightPoiType.mountain,
        sitelinks: 1000 - i,
      ),
      routeProgress: i / count,
    ),
  );
}

class _TestFlightPreviewCubit extends FlightPreviewCubit {
  _TestFlightPreviewCubit({
    required super.departure,
    required super.arrival,
    super.flightNumber,
    super.airlineCodeHint,
    super.airlineNameHint,
    super.schedule,
    super.fetchFlightWeatherUseCase,
    super.hasPendingFlightUnlock,
    required super.connectivityChecker,
    required super.getRouteOverviewUseCase,
    required super.buildFlightRoutePreviewUseCase,
    required super.downloadMapUseCase,
    required super.downloadRegionWikiArticlesUseCase,
    required super.downloadWikipediaArticlesUseCase,
    required super.getWikiArticlesUseCase,
    required super.userFlightPrefsRepository,
    required super.flightRepository,
    required super.subscriptionRepository,
    required super.flightUnlockRepository,
    required super.deleteFlightUseCase,
    required super.analytics,
    required super.crashlytics,
  }) : super(autoPrepare: false);

  void setStateForTest(FlightPreviewState state) => emit(state);
}

FlightSchedule _tomorrowAtNoon() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return FlightSchedule.approximate(
    DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    departureTime: const ApproximateDepartureTime(hour: 12, minute: 0),
  );
}

class _CountingWeatherForecastProvider implements WeatherForecastProvider {
  int calls = 0;

  @override
  Future<WeatherForecastBatch> forecastBatch({
    required List<WeatherForecastRequest> requests,
    required DateTime windowStartUtc,
    required DateTime windowEndUtc,
  }) async {
    calls++;
    return WeatherForecastBatch(
      seriesByRequest: [
        for (final request in requests)
          [
            WeatherForecastPoint(
              timeUtc: request.targetTimeUtc,
              temperatureC: 18,
              windSpeedMs: 3,
              cloudCoverPercent: 25,
              cloudLowPercent: 10,
              cloudMidPercent: 10,
              cloudHighPercent: 5,
              precipitationMm: 0,
              symbolCode: 'fair_day',
            ),
          ],
      ],
      retrievedAtUtc: DateTime.now().toUtc(),
      attribution: WeatherAttribution.metNorway,
    );
  }
}

class _FakeConnectivityChecker implements ConnectivityChecker {
  bool hasInternet = true;

  @override
  Future<bool> hasInternetConnectivity({
    Duration timeout = const Duration(seconds: 2),
  }) async => hasInternet;
}

class _FakeGetRouteOverviewUseCase implements GetRouteOverviewUseCase {
  _FakeGetRouteOverviewUseCase({required this.routeOverview});

  RouteOverview routeOverview;

  @override
  Future<RouteOverview> call({
    required Airport departure,
    required Airport arrival,
  }) async {
    return routeOverview;
  }

  @override
  RouteOverview fromPayload({
    required Map<String, dynamic> payload,
    required Airport departure,
    required Airport arrival,
  }) {
    throw UnimplementedError();
  }
}

class _FakeBuildFlightRoutePreviewUseCase
    extends BuildFlightRoutePreviewUseCase {
  _FakeBuildFlightRoutePreviewUseCase({this.error})
    : super(repository: _UnusedFlightSearchRepository());

  /// Thrown on call when set (e.g. a not-found for unrecorded routes).
  final Object? error;

  @override
  Future<FlightRoutePreviewResult> call({
    required String flightNumber,
    String? fr24Id,
    String? origCode,
    String? destCode,
    required String lang,
  }) {
    throw error ?? UnimplementedError();
  }
}

class _UnusedFlightSearchRepository implements FlightSearchRepository {
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
  Future<List<FlightSummary>> searchFlightsByNumber(String flightNumber) {
    throw UnimplementedError();
  }

  @override
  Future<List<FlightSummary>> searchUpcomingFlightsByNumber(
    String flightNumber, {
    DateTime? date,
  }) {
    throw UnimplementedError();
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
  Future<String?> resolveAirlineNameByCode(String? code) {
    throw UnimplementedError();
  }

  @override
  Future<List<FlightSummary>> searchFlightsByRoute({
    required String departureCode,
    required String arrivalCode,
  }) {
    throw UnimplementedError();
  }
}

class _FakeDownloadMapUseCase implements DownloadMapUseCase {
  int? lastMaxZoom;
  String? lastFlightAccessTier;

  @override
  void cancel() {}

  @override
  Stream<DownloadMapEvent> call({
    required String flightId,
    required FlightRoute flightRoute,
    required FlightInfo flightInfo,
    FlightOperationalData? flightOperationalData,
    FlightSchedule? flightSchedule,
    required String flightAccessTier,
    required int maxZoom,
  }) {
    lastMaxZoom = maxZoom;
    lastFlightAccessTier = flightAccessTier;
    return Stream<DownloadMapEvent>.fromIterable([
      DownloadMapInitializing(),
      DownloadMapDone('/tmp/test.mbtiles', 1024),
    ]);
  }
}

class _FakeDownloadWikipediaArticlesUseCase
    implements DownloadWikipediaArticlesUseCase {
  List<String> lastRequestedUrls = const [];

  @override
  void cancel() {}

  @override
  Future<void> cleanupBundleMedia(String bundleId) async {}

  @override
  Future<WikipediaArticlesDownloadResult> call({
    required String bundleId,
    required List<String> articleUrls,
    required void Function(WikipediaArticlesDownloadProgress progress)
    onProgress,
  }) async {
    lastRequestedUrls = List<String>.from(articleUrls);
    return const WikipediaArticlesDownloadResult(
      articles: [],
      failedCount: 0,
      cancelled: false,
    );
  }
}

class _FakeDownloadRegionWikiArticlesUseCase
    implements DownloadRegionWikiArticlesUseCase {
  String? lastPreferredLanguageCode;
  Set<String> lastRequestedRegionQids = const {};

  @override
  void cancel() {}

  @override
  int downloadTargetCount(List<RouteRegion> regions) => regions.length;

  @override
  Future<RegionWikiArticlesDownloadResult> call({
    required List<RouteRegion> regions,
    required String preferredLanguageCode,
    required void Function(RegionWikiArticlesDownloadProgress progress)
    onProgress,
  }) async {
    lastPreferredLanguageCode = preferredLanguageCode;
    lastRequestedRegionQids = {for (final region in regions) region.qid};
    onProgress(
      RegionWikiArticlesDownloadProgress(
        completed: regions.length,
        total: regions.length,
        failed: 0,
      ),
    );
    return RegionWikiArticlesDownloadResult(
      regions: List<RouteRegion>.from(regions),
      articleUrls: const [],
      failedCount: 0,
      cancelled: false,
    );
  }
}

class _FakeGetWikiArticlesUseCase implements GetWikiArticlesUseCase {
  @override
  Future<List<WikiArticleCandidate>> call({
    required String airportDeparture,
    required String airportArrival,
    required List<LatLng> waypoints,
    List<UsersInterests>? interests,
  }) async => const [];
}

class _FakeUserFlightPrefsRepository implements UserFlightPrefsRepository {
  @override
  Future<UserFlightPrefs> getPrefs() async => const UserFlightPrefs.empty();
}

class _FakeAppAnalytics implements AppAnalytics {
  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {}

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {}

  @override
  Future<void> log(AnalyticsEvent event) async {}
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

class _FakeDeleteFlightUseCase implements DeleteFlightUseCase {
  @override
  Future<bool> call(String flightId) async => true;
}

class _FakeFlightRepository implements FlightRepository {
  @override
  Future<bool> updateFlightAccessTier({
    required String flightId,
    required String accessTier,
  }) async => true;

  @override
  Future<bool> updateFlightSchedule({
    required String flightId,
    required FlightSchedule schedule,
  }) async => true;

  @override
  Future<List<Flight>> getAllFlights() async => const [];

  @override
  Future<Flight?> getFlightById(String flightId) async => null;

  @override
  Future<int> getTotalDownloadedMaps() async => 0;

  @override
  Future<int> getTotalFlights() async => 0;

  @override
  Future<int> getTotalMapSize() async => 0;

  @override
  Future<double> getTotalFlightDistanceKm() async => 0;

  @override
  Future<String> insertFlight(Flight flight) async => flight.id;

  @override
  Future<String> saveOrUpdateFlight(Flight flight) async => flight.id;

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

class _FakeSubscriptionRepository implements SubscriptionRepository {
  bool isPro = false;

  @override
  Stream<SubscriptionStatus> get statusStream =>
      const Stream<SubscriptionStatus>.empty();

  @override
  SubscriptionStatus get currentStatus => SubscriptionStatus(
    isPro: isPro,
    entitlementId: 'Flymap Pro',
    lastUpdatedAt: DateTime.now(),
  );

  @override
  Future<SubscriptionStatus> initialize() async => currentStatus;

  @override
  Future<SubscriptionStatus> refresh() async => currentStatus;

  @override
  Future<SubscriptionStatus> restorePurchases() async => currentStatus;

  @override
  Future<List<SubscriptionProduct>> getProducts() async => const [];

  @override
  Future<SubscriptionStatus> purchasePackage({
    required String packageId,
  }) async {
    isPro = true;
    return currentStatus;
  }

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded() async =>
      SubscriptionPaywallResult.cancelled;

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<void> close() async {}
}

class _FakeFlightUnlockRepository implements FlightUnlockRepository {
  final _controller = StreamController<int>.broadcast();
  int unusedCount = 0;
  int consumeCount = 0;

  @override
  Stream<int> get balanceStream => _controller.stream;

  @override
  int get currentUnusedUnlockCount => unusedCount;

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  Future<int> consumeUnlock() async {
    consumeCount++;
    unusedCount = unusedCount > 0 ? unusedCount - 1 : 0;
    _controller.add(unusedCount);
    return unusedCount;
  }

  @override
  Future<FlightUnlockProduct?> getUnlockProduct() async => null;

  @override
  Future<int> initialize() async => unusedCount;

  @override
  Future<FlightUnlockPurchaseResult> purchaseUnlock() async =>
      const FlightUnlockPurchaseResult.cancelled();

  @override
  Future<int> restoreUnlock() async {
    unusedCount++;
    _controller.add(unusedCount);
    return unusedCount;
  }
}

class _TestFirebaseFunctionsException extends FirebaseFunctionsException {
  _TestFirebaseFunctionsException({
    required super.code,
    required super.message,
  });
}
