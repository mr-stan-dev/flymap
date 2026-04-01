import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/usecase/build_wikipedia_candidates_use_case.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('FlightSearchScreenCubit wiki selection', () {
    late _FakeDownloadWikipediaArticlesUseCase wikiDownloadUseCase;
    late _FakeDownloadMapUseCase mapUseCase;
    late _TestFlightSearchScreenCubit cubit;

    setUp(() {
      wikiDownloadUseCase = _FakeDownloadWikipediaArticlesUseCase();
      mapUseCase = _FakeDownloadMapUseCase();
      cubit = _TestFlightSearchScreenCubit(
        airportsDb: _FakeAirportsDatabase(),
        favoritesRepository: _FakeFavoriteAirportsRepository(),
        routeProvider: _FakeRouteProvider(),
        downloadMapUseCase: mapUseCase,
        buildWikipediaCandidatesUseCase: _FakeBuildWikipediaCandidatesUseCase(),
        downloadWikipediaArticlesUseCase: wikiDownloadUseCase,
        getFlightInfoUseCase: _FakeGetFlightInfoUseCase(),
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
        cubit.setStateForTest(
          cubit.state.copyWith(
            selectedArticleUrls: [_url(1), _url(2), _url(3), _url(4)],
          ),
        );

        await cubit.startDownload(isPro: false);

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
        cubit.setStateForTest(
          cubit.state.copyWith(
            selectedArticleUrls: [_url(1), _url(2), _url(3), _url(4)],
          ),
        );

        await cubit.startDownload(isPro: true);

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

    test('selectMapDetailLevel updates state in map preview step', () {
      cubit.setStateForTest(
        cubit.state.copyWith(step: CreateFlightStep.mapPreview),
      );

      cubit.selectMapDetailLevel(MapDetailLevel.pro);

      expect(cubit.state.selectedMapDetailLevel, MapDetailLevel.pro);
    });

    test('route selection reset sets map detail level back to basic', () async {
      final route = _route();
      cubit.setStateForTest(
        cubit.state.copyWith(
          step: CreateFlightStep.arrival,
          selectedDeparture: route.departure,
          selectedMapDetailLevel: MapDetailLevel.pro,
        ),
      );

      await cubit.selectAirport(route.arrival);

      expect(cubit.state.selectedMapDetailLevel, MapDetailLevel.basic);
    });

    test('startDownload passes z10 for basic short route', () async {
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          selectedMapDetailLevel: MapDetailLevel.basic,
          flightRoute: _route(),
          isTooLongFlight: false,
        ),
      );

      await cubit.startDownload(isPro: true);

      expect(mapUseCase.lastMaxZoom, 10);
    });

    test('startDownload passes z9 for basic long route', () async {
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          selectedMapDetailLevel: MapDetailLevel.basic,
          flightRoute: _longRoute(),
          isTooLongFlight: false,
        ),
      );

      await cubit.startDownload(isPro: true);

      expect(mapUseCase.lastMaxZoom, 9);
    });

    test('startDownload passes z11 for pro short route', () async {
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          selectedMapDetailLevel: MapDetailLevel.pro,
          flightRoute: _route(),
          isTooLongFlight: false,
        ),
      );

      await cubit.startDownload(isPro: true);

      expect(mapUseCase.lastMaxZoom, 11);
    });

    test('startDownload passes z10 for pro long route', () async {
      cubit.setStateForTest(
        cubit.state.copyWith(
          selectedArticleUrls: const [],
          selectedMapDetailLevel: MapDetailLevel.pro,
          flightRoute: _longRoute(),
          isTooLongFlight: false,
        ),
      );

      await cubit.startDownload(isPro: true);

      expect(mapUseCase.lastMaxZoom, 10);
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

class _TestFlightSearchScreenCubit extends FlightSearchScreenCubit {
  _TestFlightSearchScreenCubit({
    required super.airportsDb,
    required super.favoritesRepository,
    required super.routeProvider,
    required super.downloadMapUseCase,
    required super.buildWikipediaCandidatesUseCase,
    required super.downloadWikipediaArticlesUseCase,
    required super.getFlightInfoUseCase,
  }) : super(autoInitialize: false);

  void setStateForTest(FlightSearchScreenState state) => emit(state);
}

class _FakeAirportsDatabase implements AirportsDatabase {
  @override
  Iterable<Airport> get allAirports => const [];

  @override
  Airport? findByCode(String code) => null;

  @override
  Future<void> initialize() async {}

  @override
  List<Airport> search(String query) => const [];
}

class _FakeFavoriteAirportsRepository implements FavoriteAirportsRepository {
  @override
  Future<void> addFavorite(String code) async {}

  @override
  Future<List<String>> getFavoriteCodes() async => const [];

  @override
  Future<bool> isFavorite(String code) async => false;

  @override
  Future<void> toggleFavorite(String code) async {}

  @override
  Future<void> touchFavorite(String code) async {}
}

class _FakeRouteProvider implements FlightRouteProvider {
  @override
  FlightRoute getRoute({
    required Airport departure,
    required Airport arrival,
  }) => _route();
}

class _FakeBuildWikipediaCandidatesUseCase
    implements BuildWikipediaCandidatesUseCase {
  @override
  List<WikiArticleCandidate> call({required FlightInfo flightInfo}) => const [];
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
    return const Stream<DownloadMapEvent>.empty();
  }
}

class _FakeDownloadWikipediaArticlesUseCase
    implements DownloadWikipediaArticlesUseCase {
  List<String> lastRequestedUrls = const [];

  @override
  void cancel() {}

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
