import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/download_poi_summaries_use_case.dart';
import 'package:flymap/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';
import 'package:flymap/usecase/delete_flight_use_case.dart';
import 'package:flymap/usecase/get_flight_poi_use_case.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('FlightPreviewCubit wiki selection', () {
    late _FakeDownloadWikipediaArticlesUseCase wikiDownloadUseCase;
    late _FakeDownloadPoiSummariesUseCase poiDownloadUseCase;
    late _FakeDownloadMapUseCase mapUseCase;
    late _FakeConnectivityChecker connectivityChecker;
    late _FakeGetFlightPOIUseCase poiUseCase;
    late _FakeSubscriptionRepository subscriptionRepository;
    late _TestFlightPreviewCubit cubit;

    setUp(() {
      wikiDownloadUseCase = _FakeDownloadWikipediaArticlesUseCase();
      poiDownloadUseCase = _FakeDownloadPoiSummariesUseCase();
      mapUseCase = _FakeDownloadMapUseCase();
      connectivityChecker = _FakeConnectivityChecker();
      poiUseCase = _FakeGetFlightPOIUseCase();
      subscriptionRepository = _FakeSubscriptionRepository();
      final route = _route();
      cubit = _TestFlightPreviewCubit(
        departure: route.departure,
        arrival: route.arrival,
        connectivityChecker: connectivityChecker,
        routeProvider: _FakeRouteProvider(),
        downloadMapUseCase: mapUseCase,
        downloadPoiSummariesUseCase: poiDownloadUseCase,
        downloadWikipediaArticlesUseCase: wikiDownloadUseCase,
        getFlightInfoUseCase: _FakeGetFlightInfoUseCase(),
        getFlightPOIUseCase: poiUseCase,
        flightRepository: _FakeFlightRepository(),
        subscriptionRepository: subscriptionRepository,
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

    test('default selected map detail level is basic', () {
      expect(cubit.state.selectedMapDetailLevel, MapDetailLevel.basic);
    });

    test('default selected map detail level is pro for pro users', () async {
      final proSubscriptionRepository = _FakeSubscriptionRepository()
        ..isPro = true;
      final route = _route();
      final proCubit = _TestFlightPreviewCubit(
        departure: route.departure,
        arrival: route.arrival,
        connectivityChecker: _FakeConnectivityChecker(),
        routeProvider: _FakeRouteProvider(),
        downloadMapUseCase: _FakeDownloadMapUseCase(),
        downloadPoiSummariesUseCase: _FakeDownloadPoiSummariesUseCase(),
        downloadWikipediaArticlesUseCase: _FakeDownloadWikipediaArticlesUseCase(),
        getFlightInfoUseCase: _FakeGetFlightInfoUseCase(),
        getFlightPOIUseCase: _FakeGetFlightPOIUseCase(),
        flightRepository: _FakeFlightRepository(),
        subscriptionRepository: proSubscriptionRepository,
        deleteFlightUseCase: _FakeDeleteFlightUseCase(),
        analytics: _FakeAppAnalytics(),
        crashlytics: _FakeAppCrashlytics(),
      );
      addTearDown(proCubit.close);

      expect(proCubit.state.selectedMapDetailLevel, MapDetailLevel.pro);
    });

    test('selectMapDetailLevel updates state in map preview step', () {
      cubit.setStateForTest(
        cubit.state.copyWith(step: CreateFlightStep.mapPreview),
      );

      cubit.selectMapDetailLevel(MapDetailLevel.pro);

      expect(cubit.state.selectedMapDetailLevel, MapDetailLevel.pro);
    });

    test('startDownload passes z10 for basic short route', () async {
      subscriptionRepository.isPro = true;
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          selectedMapDetailLevel: MapDetailLevel.basic,
          flightRoute: _route(),
        ),
      );

      await cubit.startDownload();

      expect(mapUseCase.lastMaxZoom, 10);
    });

    test('startDownload passes z9 for basic long route', () async {
      subscriptionRepository.isPro = true;
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          selectedMapDetailLevel: MapDetailLevel.basic,
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
          selectedMapDetailLevel: MapDetailLevel.pro,
          flightRoute: _route(),
        ),
      );

      await cubit.startDownload();

      expect(mapUseCase.lastMaxZoom, 11);
      expect(poiUseCase.lastRequestedMapDetail, MapDetailLevel.pro);
    });

    test('startDownload passes z10 for pro long route', () async {
      subscriptionRepository.isPro = true;
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          selectedMapDetailLevel: MapDetailLevel.pro,
          flightRoute: _longRoute(),
        ),
      );

      await cubit.startDownload();

      expect(mapUseCase.lastMaxZoom, 10);
    });

    test('offline map preview shows error state flag', () async {
      connectivityChecker.hasInternet = false;
      cubit.setStateForTest(
        cubit.state.copyWith(step: CreateFlightStep.mapPreview),
      );
      await cubit.preparePreview();

      expect(cubit.state.step, CreateFlightStep.mapPreview);
      expect(cubit.state.isPreviewLoading, isFalse);
      expect(cubit.state.hasInternetForMapPreview, isFalse);
    });

    test('refreshPoisForPro requests POIs with pro detail level', () async {
      cubit.setStateForTest(
        cubit.state.copyWith(
          flightRoute: _route(),
          selectedMapDetailLevel: MapDetailLevel.basic,
        ),
      );

      await cubit.refreshPoisForPro();

      expect(poiUseCase.lastRequestedMapDetail, MapDetailLevel.pro);
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
  return const FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [LatLng(10, 10), LatLng(20, 20)],
    corridor: [LatLng(10, 10), LatLng(20, 20)],
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
  return const FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [LatLng(10, 10), LatLng(35, 35)],
    corridor: [LatLng(10, 10), LatLng(35, 35)],
  );
}

class _TestFlightPreviewCubit extends FlightPreviewCubit {
  _TestFlightPreviewCubit({
    required super.departure,
    required super.arrival,
    required super.connectivityChecker,
    required super.routeProvider,
    required super.downloadMapUseCase,
    required super.downloadPoiSummariesUseCase,
    required super.downloadWikipediaArticlesUseCase,
    required super.getFlightInfoUseCase,
    required super.getFlightPOIUseCase,
    required super.flightRepository,
    required super.subscriptionRepository,
    required super.deleteFlightUseCase,
    required super.analytics,
    required super.crashlytics,
  }) : super(autoPrepare: false);

  void setStateForTest(FlightPreviewState state) => emit(state);
}

class _FakeConnectivityChecker implements ConnectivityChecker {
  bool hasInternet = true;

  @override
  Future<bool> hasInternetConnectivity({
    Duration timeout = const Duration(seconds: 2),
  }) async => hasInternet;
}

class _FakeRouteProvider implements FlightRouteProvider {
  @override
  FlightRoute getRoute({
    required Airport departure,
    required Airport arrival,
  }) => _route();
}

class _FakeDownloadMapUseCase implements DownloadMapUseCase {
  int? lastMaxZoom;

  @override
  void cancel() {}

  @override
  Stream<DownloadMapEvent> call({
    required FlightRoute flightRoute,
    required FlightInfo flightInfo,
    required int maxZoom,
  }) {
    lastMaxZoom = maxZoom;
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

class _FakeDownloadPoiSummariesUseCase implements DownloadPoiSummariesUseCase {
  @override
  void cancel() {}

  @override
  Future<PoiSummariesDownloadResult> call({
    required List<RoutePoiSummary> pois,
    required String preferredLanguageCode,
    required void Function(PoiSummariesDownloadProgress progress) onProgress,
  }) async {
    return PoiSummariesDownloadResult(
      pois: List<RoutePoiSummary>.from(pois),
      failedCount: 0,
      cancelled: false,
    );
  }
}

class _FakeGetFlightInfoUseCase implements GetFlightInfoUseCase {
  @override
  Future<FlightInfo> call({
    required String airportDeparture,
    required String airportArrival,
    required List<LatLng> waypoints,
  }) async => FlightInfo.empty;

  @override
  Future<List<WikiArticleCandidate>> getWikiArticleCandidates({
    required String airportDeparture,
    required String airportArrival,
    required List<LatLng> waypoints,
  }) async => const [];
}

class _FakeGetFlightPOIUseCase implements GetFlightPOIUseCase {
  MapDetailLevel? lastRequestedMapDetail;

  @override
  Future<List<RoutePoiSummary>> call({
    required FlightRoute route,
    required MapDetailLevel mapDetail,
  }) async {
    lastRequestedMapDetail = mapDetail;
    return const [];
  }
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
  Future<String> insertFlight(Flight flight) async => flight.id;

  @override
  Future<String> saveOrUpdateFlight(Flight flight) async => flight.id;

  @override
  Future<bool> updateFlightInfo({
    required String flightId,
    required FlightInfo info,
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
