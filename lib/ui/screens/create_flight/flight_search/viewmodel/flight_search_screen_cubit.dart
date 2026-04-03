import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/map_download_config.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/subscription/pro_limits.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/popular_flights.dart';
import 'package:flymap/usecase/build_wikipedia_candidates_use_case.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';

class FlightSearchScreenCubit extends Cubit<FlightSearchScreenState> {
  FlightSearchScreenCubit({
    required AirportsDatabase airportsDb,
    required FavoriteAirportsRepository favoritesRepository,
    required ConnectivityChecker connectivityChecker,
    required FlightRouteProvider routeProvider,
    required DownloadMapUseCase downloadMapUseCase,
    required BuildWikipediaCandidatesUseCase buildWikipediaCandidatesUseCase,
    required DownloadWikipediaArticlesUseCase downloadWikipediaArticlesUseCase,
    required GetFlightInfoUseCase getFlightInfoUseCase,
    required AppAnalytics analytics,
    required AppCrashlytics crashlytics,
    bool autoInitialize = true,
  }) : _airportsDb = airportsDb,
       _favoritesRepository = favoritesRepository,
       _connectivityChecker = connectivityChecker,
       _routeProvider = routeProvider,
       _downloadMapUseCase = downloadMapUseCase,
       _buildWikipediaCandidatesUseCase = buildWikipediaCandidatesUseCase,
       _downloadWikipediaArticlesUseCase = downloadWikipediaArticlesUseCase,
       _getFlightInfoUseCase = getFlightInfoUseCase,
       _analytics = analytics,
       _crashlytics = crashlytics,
       super(FlightSearchScreenState.initial()) {
    if (autoInitialize) {
      _initialize();
    }
  }

  final _logger = Logger('FlightSearchScreenCubit');
  final AirportsDatabase _airportsDb;
  final FavoriteAirportsRepository _favoritesRepository;
  final ConnectivityChecker _connectivityChecker;
  final FlightRouteProvider _routeProvider;
  final DownloadMapUseCase _downloadMapUseCase;
  final BuildWikipediaCandidatesUseCase _buildWikipediaCandidatesUseCase;
  final DownloadWikipediaArticlesUseCase _downloadWikipediaArticlesUseCase;
  final GetFlightInfoUseCase _getFlightInfoUseCase;
  final AppAnalytics _analytics;
  final AppCrashlytics _crashlytics;

  StreamSubscription? _downloadSubscription;
  bool _downloadCancelled = false;

  int get _freeWikiArticlesSelectionLimit =>
      ProLimits.freeWikiArticlesSelectionLimit;

  Future<void> _initialize() async {
    try {
      await _airportsDb.initialize();
      final popularAirports = await loadPopularAirports();
      final favoriteAirports = await _loadFavoriteAirports();
      emit(
        state.copyWith(
          popularAirports: popularAirports,
          favoriteAirports: favoriteAirports,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      _logger.error('Failed to initialize create-flight flow: $e');
      emit(
        state.copyWith(errorMessage: t.createFlight.errors.failedLoadAirports),
      );
    }
  }

  Future<void> searchAirports(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      emit(
        state.copyWith(
          searchQuery: '',
          searchResults: const [],
          isSearchLoading: false,
          clearErrorMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        searchQuery: normalized,
        isSearchLoading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final results = _airportsDb.search(normalized).take(20).toList();
      emit(
        state.copyWith(
          searchQuery: normalized,
          searchResults: _applyStepAirportFilter(results),
          isSearchLoading: false,
        ),
      );
    } catch (e) {
      _logger.error('Airport search failed: $e');
      emit(
        state.copyWith(
          isSearchLoading: false,
          searchResults: const [],
          errorMessage: t.createFlight.errors.airportSearchFailed,
        ),
      );
    }
  }

  Future<void> selectAirport(Airport airport) async {
    if (state.step == CreateFlightStep.arrival &&
        _sameAirportAsDeparture(airport)) {
      return;
    }

    final isFavorite = await _isFavorite(airport);

    switch (state.step) {
      case CreateFlightStep.departure:
        emit(
          state.copyWith(
            selectedDeparture: airport,
            clearSelectedArrival: true,
            searchQuery: _airportSearchLabel(airport),
            searchResults: const [],
            isSearchLoading: false,
            selectedAirportIsFavorite: isFavorite,
            clearFlightRoute: true,
            selectedMapDetailLevel: MapDetailLevel.basic,
            flightInfo: FlightInfo.empty,
            articleCandidates: const [],
            clearSelectedArticleUrls: true,
            isWikiSuggestionsLoading: false,
            isPreviewLoading: false,
            isOverviewLoading: false,
            isTooLongFlight: false,
            hasInternetForMapPreview: true,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        break;
      case CreateFlightStep.arrival:
        emit(
          state.copyWith(
            selectedArrival: airport,
            searchQuery: _airportSearchLabel(airport),
            searchResults: const [],
            isSearchLoading: false,
            selectedAirportIsFavorite: isFavorite,
            clearFlightRoute: true,
            selectedMapDetailLevel: MapDetailLevel.basic,
            flightInfo: FlightInfo.empty,
            articleCandidates: const [],
            clearSelectedArticleUrls: true,
            isWikiSuggestionsLoading: false,
            isPreviewLoading: false,
            isOverviewLoading: false,
            isTooLongFlight: false,
            hasInternetForMapPreview: true,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        break;
      case CreateFlightStep.mapPreview:
      case CreateFlightStep.routeNotSupported:
      case CreateFlightStep.overview:
      case CreateFlightStep.wikipediaArticles:
        break;
    }
  }

  Future<void> toggleFavoriteForSelectedAirport() async {
    final airport = switch (state.step) {
      CreateFlightStep.departure => state.selectedDeparture,
      CreateFlightStep.arrival => state.selectedArrival,
      CreateFlightStep.routeNotSupported ||
      CreateFlightStep.mapPreview ||
      CreateFlightStep.overview ||
      CreateFlightStep.wikipediaArticles => null,
    };
    if (airport == null) return;

    final code = _airportCode(airport);
    if (code.isEmpty) return;

    await _favoritesRepository.toggleFavorite(code);
    final isFavorite = await _favoritesRepository.isFavorite(code);
    await _refreshFavorites();
    emit(state.copyWith(selectedAirportIsFavorite: isFavorite));
  }

  Future<void> toggleFavoriteForAirport(Airport airport) async {
    final code = _airportCode(airport);
    if (code.isEmpty) return;

    await _favoritesRepository.toggleFavorite(code);
    final isFavorite = await _favoritesRepository.isFavorite(code);
    await _refreshFavorites();

    final selected = switch (state.step) {
      CreateFlightStep.departure => state.selectedDeparture,
      CreateFlightStep.arrival => state.selectedArrival,
      CreateFlightStep.routeNotSupported ||
      CreateFlightStep.mapPreview ||
      CreateFlightStep.overview ||
      CreateFlightStep.wikipediaArticles => null,
    };

    if (_airportCode(selected) == code) {
      emit(state.copyWith(selectedAirportIsFavorite: isFavorite));
    }
  }

  void clearSelectedAirportForCurrentStep() {
    switch (state.step) {
      case CreateFlightStep.departure:
        emit(
          state.copyWith(
            clearSelectedDeparture: true,
            selectedAirportIsFavorite: false,
            searchQuery: '',
            searchResults: const [],
            isSearchLoading: false,
            hasInternetForMapPreview: true,
            clearErrorMessage: true,
          ),
        );
        break;
      case CreateFlightStep.arrival:
        emit(
          state.copyWith(
            clearSelectedArrival: true,
            selectedAirportIsFavorite: false,
            searchQuery: '',
            searchResults: const [],
            isSearchLoading: false,
            hasInternetForMapPreview: true,
            clearErrorMessage: true,
          ),
        );
        break;
      case CreateFlightStep.mapPreview:
      case CreateFlightStep.routeNotSupported:
      case CreateFlightStep.overview:
      case CreateFlightStep.wikipediaArticles:
        break;
    }
  }

  Future<void> continueFromAirportStep() async {
    switch (state.step) {
      case CreateFlightStep.departure:
        final departure = state.selectedDeparture;
        if (departure == null) return;
        await _touchFavoriteIfNeeded(departure);
        emit(
          state.copyWith(
            step: CreateFlightStep.arrival,
            searchQuery: '',
            searchResults: const [],
            isSearchLoading: false,
            selectedAirportIsFavorite: false,
            clearSelectedArrival: true,
            clearFlightRoute: true,
            selectedMapDetailLevel: MapDetailLevel.basic,
            flightInfo: FlightInfo.empty,
            articleCandidates: const [],
            clearSelectedArticleUrls: true,
            isWikiSuggestionsLoading: false,
            isPreviewLoading: false,
            isOverviewLoading: false,
            isTooLongFlight: false,
            hasInternetForMapPreview: true,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        break;
      case CreateFlightStep.arrival:
        final arrival = state.selectedArrival;
        if (arrival == null || _sameAirportAsDeparture(arrival)) return;
        await _touchFavoriteIfNeeded(arrival);
        emit(
          state.copyWith(
            step: CreateFlightStep.mapPreview,
            searchQuery: '',
            searchResults: const [],
            isSearchLoading: false,
            selectedAirportIsFavorite: false,
            clearFlightRoute: true,
            selectedMapDetailLevel: MapDetailLevel.basic,
            flightInfo: FlightInfo.empty,
            articleCandidates: const [],
            clearSelectedArticleUrls: true,
            isWikiSuggestionsLoading: false,
            isPreviewLoading: true,
            isOverviewLoading: false,
            isTooLongFlight: false,
            hasInternetForMapPreview: true,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        await _preparePreview();
        break;
      case CreateFlightStep.mapPreview:
      case CreateFlightStep.routeNotSupported:
      case CreateFlightStep.overview:
      case CreateFlightStep.wikipediaArticles:
        break;
    }
  }

  Future<void> continueFromMap() async {
    if (!state.canContinueFromMap) return;
    emit(
      state.copyWith(
        step: CreateFlightStep.overview,
        clearErrorMessage: true,
        clearDownloadErrorMessage: true,
      ),
    );
  }

  void selectMapDetailLevel(MapDetailLevel detailLevel) {
    if (state.step != CreateFlightStep.mapPreview) return;
    if (state.selectedMapDetailLevel == detailLevel) return;
    emit(
      state.copyWith(
        selectedMapDetailLevel: detailLevel,
        clearErrorMessage: true,
      ),
    );
  }

  void continueFromOverview() {
    if (state.flightRoute == null) return;
    emit(
      state.copyWith(
        step: CreateFlightStep.wikipediaArticles,
        clearErrorMessage: true,
        clearDownloadErrorMessage: true,
      ),
    );
  }

  void toggleWikiArticleSelection(String url) {
    if (state.step != CreateFlightStep.wikipediaArticles) return;
    if (!state.articleCandidates.any((candidate) => candidate.url == url)) {
      return;
    }

    final current = state.selectedArticleUrls.toList();
    final currentSet = current.toSet();
    if (currentSet.contains(url)) {
      current.removeWhere((item) => item == url);
      emit(
        state.copyWith(selectedArticleUrls: current, clearErrorMessage: true),
      );
      return;
    }

    current.add(url);
    emit(state.copyWith(selectedArticleUrls: current, clearErrorMessage: true));
  }

  void toggleAllWikiArticleSelections() {
    if (state.step != CreateFlightStep.wikipediaArticles) return;
    final candidateUrls = state.articleCandidates.map((e) => e.url).toList();
    if (candidateUrls.isEmpty) return;

    final selectedSet = state.selectedArticleUrls.toSet();
    final allSelected = candidateUrls.every(selectedSet.contains);

    emit(
      state.copyWith(
        selectedArticleUrls: allSelected ? const [] : candidateUrls,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> startDownload({required bool isPro}) async {
    if (state.isDownloading) return;
    final route = state.flightRoute;
    if (route == null) return;

    _downloadCancelled = false;
    await _downloadSubscription?.cancel();

    final selectedUrls =
        (isPro
                ? state.selectedArticleUrls
                : state.selectedArticleUrls.take(
                    _freeWikiArticlesSelectionLimit,
                  ))
            .toList();
    if (!isPro && selectedUrls.length != state.selectedArticleUrls.length) {
      emit(state.copyWith(selectedArticleUrls: selectedUrls));
    }
    final hasArticlePhase = selectedUrls.isNotEmpty;
    final baseInfo = state.flightInfo;
    final effectiveMaxZoom = MapDownloadConfig.resolveMaxZoom(
      distanceKm: route.distanceInKm,
      detailLevel: state.selectedMapDetailLevel,
    );
    final routeLengthKm = route.distanceInKm;

    emit(
      state.copyWith(
        isDownloading: true,
        downloadProgress: 0.0,
        downloadedBytes: 0,
        downloadStage: hasArticlePhase
            ? DownloadStage.downloadingArticles
            : DownloadStage.initializing,
        articleDownloadCompleted: 0,
        articleDownloadTotal: selectedUrls.length,
        articleDownloadFailed: 0,
        clearDownloadTileCount: true,
        clearDownloadWorkerCount: true,
        downloadDone: false,
        clearDownloadErrorMessage: true,
        clearErrorMessage: true,
      ),
    );
    unawaited(
      _analytics.log(
        DownloadStartedEvent(
          routeLengthKm: routeLengthKm,
          mapDetail: state.selectedMapDetailLevel,
          articlesSelectedCount: selectedUrls.length,
          isProUser: isPro,
        ),
      ),
    );
    unawaited(
      _crashlytics.setContext(
        screen: 'create_flight_download',
        routeLengthKm: routeLengthKm.round(),
        mapDetail: state.selectedMapDetailLevel.name,
        articlesSelectedCount: selectedUrls.length,
        downloadStage: hasArticlePhase
            ? 'downloading_articles'
            : 'initializing',
      ),
    );

    List<FlightArticle> downloadedArticles = const [];
    if (hasArticlePhase) {
      try {
        final result = await _downloadWikipediaArticlesUseCase.call(
          bundleId: _articleBundleId(route),
          articleUrls: selectedUrls,
          onProgress: (progress) {
            if (_downloadCancelled || isClosed) return;
            emit(
              state.copyWith(
                isDownloading: true,
                downloadStage: DownloadStage.downloadingArticles,
                articleDownloadCompleted: progress.completed,
                articleDownloadTotal: progress.total,
                articleDownloadFailed: progress.failed,
                downloadProgress: 0.0,
                downloadDone: false,
              ),
            );
          },
        );

        if (_downloadCancelled || isClosed || result.cancelled) return;

        downloadedArticles = result.articles;
        emit(
          state.copyWith(
            isDownloading: true,
            downloadStage: DownloadStage.initializing,
            articleDownloadCompleted: selectedUrls.length,
            articleDownloadTotal: selectedUrls.length,
            articleDownloadFailed: result.failedCount,
            downloadProgress: 0.0,
          ),
        );
      } catch (e) {
        _logger.error(
          'Article download failed; continuing with map-only download: $e',
        );
        unawaited(
          _crashlytics.recordError(
            e,
            StackTrace.current,
            reason: 'article_download_failed',
          ),
        );
        if (_downloadCancelled || isClosed) return;
        emit(
          state.copyWith(
            isDownloading: true,
            downloadStage: DownloadStage.initializing,
            articleDownloadCompleted: selectedUrls.length,
            articleDownloadTotal: selectedUrls.length,
            articleDownloadFailed: selectedUrls.length,
            downloadProgress: 0.0,
            errorMessage: t.createFlight.errors.someArticlesFailed,
          ),
        );
      }
    }

    if (_downloadCancelled || isClosed) return;

    final infoForSave = baseInfo.copyWith(articles: downloadedArticles);
    try {
      _downloadSubscription = _downloadMapUseCase
          .call(
            flightRoute: route,
            flightInfo: infoForSave,
            maxZoom: effectiveMaxZoom,
          )
          .listen((event) {
            if (_downloadCancelled || isClosed) return;
            switch (event) {
              case DownloadMapProgress():
                emit(
                  state.copyWith(
                    isDownloading: true,
                    downloadProgress: event.progress.clamp(0.0, 1.0),
                    downloadedBytes: event.downloadedBytes,
                    downloadStage: DownloadStage.downloading,
                    downloadDone: false,
                  ),
                );
                break;
              case DownloadMapDone():
                unawaited(
                  _analytics.log(
                    DownloadCompletedEvent(
                      routeLengthKm: routeLengthKm,
                      articlesDownloadedCount: downloadedArticles.length,
                      mapSizeBytes: event.fileSize,
                    ),
                  ),
                );
                unawaited(_crashlytics.setContext(downloadStage: 'completed'));
                emit(
                  state.copyWith(
                    isDownloading: false,
                    downloadProgress: 1.0,
                    downloadedBytes: event.fileSize,
                    downloadStage: DownloadStage.completed,
                    downloadDone: true,
                    clearDownloadErrorMessage: true,
                  ),
                );
                break;
              case DownloadMapError():
                unawaited(
                  _analytics.log(
                    DownloadFailedEvent(
                      stage: 'map_download',
                      errorType: 'map_download_error',
                      routeLengthKm: routeLengthKm,
                    ),
                  ),
                );
                unawaited(_crashlytics.setContext(downloadStage: 'failed'));
                unawaited(
                  _crashlytics.recordError(
                    Exception(event.errorMsg),
                    StackTrace.current,
                    reason: 'map_download_failed',
                  ),
                );
                emit(
                  state.copyWith(
                    isDownloading: false,
                    downloadStage: DownloadStage.failed,
                    downloadErrorMessage: event.errorMsg,
                  ),
                );
                break;
              case DownloadMapInitializing():
                unawaited(
                  _crashlytics.setContext(downloadStage: 'initializing'),
                );
                emit(
                  state.copyWith(
                    isDownloading: true,
                    downloadedBytes: 0,
                    downloadStage: DownloadStage.initializing,
                    downloadProgress: 0.0,
                    downloadDone: false,
                    clearDownloadTileCount: true,
                    clearDownloadWorkerCount: true,
                    clearDownloadErrorMessage: true,
                  ),
                );
                break;
              case DownloadMapComputingTiles():
                unawaited(
                  _crashlytics.setContext(downloadStage: 'computing_tiles'),
                );
                emit(
                  state.copyWith(
                    isDownloading: true,
                    downloadStage: DownloadStage.computingTiles,
                    downloadTileCount: event.totalTiles,
                  ),
                );
                break;
              case DownloadMapStartingWorkers():
                unawaited(
                  _crashlytics.setContext(downloadStage: 'starting_workers'),
                );
                emit(
                  state.copyWith(
                    isDownloading: true,
                    downloadStage: DownloadStage.startingWorkers,
                    downloadWorkerCount: event.workerCount,
                  ),
                );
                break;
              case DownloadMapFinalizing():
                unawaited(_crashlytics.setContext(downloadStage: 'finalizing'));
                emit(
                  state.copyWith(
                    isDownloading: true,
                    downloadStage: DownloadStage.finalizing,
                  ),
                );
                break;
              case DownloadMapVerifying():
                unawaited(_crashlytics.setContext(downloadStage: 'verifying'));
                emit(
                  state.copyWith(
                    isDownloading: true,
                    downloadStage: DownloadStage.verifying,
                  ),
                );
                break;
            }
          });
    } catch (e, stackTrace) {
      unawaited(
        _analytics.log(
          DownloadFailedEvent(
            stage: 'start',
            errorType: e.runtimeType.toString(),
            routeLengthKm: routeLengthKm,
          ),
        ),
      );
      unawaited(
        _crashlytics.recordError(
          e,
          stackTrace,
          reason: 'map_download_stream_setup_failed',
        ),
      );
      emit(
        state.copyWith(
          isDownloading: false,
          downloadStage: DownloadStage.failed,
          downloadErrorMessage: t.createFlight.errors.failedStartDownload(
            error: e.toString(),
          ),
        ),
      );
    }
  }

  void cancelDownload() {
    if (!state.isDownloading) return;
    _downloadCancelled = true;
    _downloadWikipediaArticlesUseCase.cancel();
    _downloadMapUseCase.cancel();
    _downloadSubscription?.cancel();
    emit(
      state.copyWith(
        isDownloading: false,
        downloadProgress: 0.0,
        downloadStage: DownloadStage.idle,
        clearDownloadTileCount: true,
        clearDownloadWorkerCount: true,
        clearErrorMessage: true,
        clearDownloadErrorMessage: true,
      ),
    );
  }

  Future<bool> handleBackAction() async {
    if (state.isDownloading) return false;

    switch (state.step) {
      case CreateFlightStep.departure:
        return true;
      case CreateFlightStep.arrival:
        final departureIsFavorite = await _isFavorite(state.selectedDeparture);
        final departureSearchLabel = state.selectedDeparture == null
            ? ''
            : _airportSearchLabel(state.selectedDeparture!);
        emit(
          state.copyWith(
            step: CreateFlightStep.departure,
            searchQuery: departureSearchLabel,
            searchResults: const [],
            isSearchLoading: false,
            selectedAirportIsFavorite: departureIsFavorite,
            hasInternetForMapPreview: true,
            clearErrorMessage: true,
          ),
        );
        return false;
      case CreateFlightStep.mapPreview:
      case CreateFlightStep.routeNotSupported:
        final arrivalIsFavorite = await _isFavorite(state.selectedArrival);
        final arrivalSearchLabel = state.selectedArrival == null
            ? ''
            : _airportSearchLabel(state.selectedArrival!);
        emit(
          state.copyWith(
            step: CreateFlightStep.arrival,
            searchQuery: arrivalSearchLabel,
            searchResults: const [],
            isSearchLoading: false,
            selectedAirportIsFavorite: arrivalIsFavorite,
            hasInternetForMapPreview: true,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        return false;
      case CreateFlightStep.overview:
        emit(
          state.copyWith(
            step: CreateFlightStep.mapPreview,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        return false;
      case CreateFlightStep.wikipediaArticles:
        emit(
          state.copyWith(
            step: CreateFlightStep.overview,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        return false;
    }
  }

  Future<void> _preparePreview() async {
    final departure = state.selectedDeparture;
    final arrival = state.selectedArrival;
    if (departure == null || arrival == null) return;

    try {
      final hasInternet = await _connectivityChecker.hasInternetConnectivity();
      if (!hasInternet) {
        emit(
          state.copyWith(
            isPreviewLoading: false,
            isWikiSuggestionsLoading: false,
            isOverviewLoading: false,
            hasInternetForMapPreview: false,
            clearErrorMessage: true,
          ),
        );
        return;
      }

      final route = _routeProvider.getRoute(
        departure: departure,
        arrival: arrival,
      );
      final routeLength = MapDownloadConfig.resolveRouteLength(
        route.distanceInKm,
      );
      unawaited(
        _analytics.log(
          SearchRoutePreparedEvent(
            routeLengthKm: route.distanceInKm,
            routeLength: routeLength,
            mapDetail: state.selectedMapDetailLevel,
          ),
        ),
      );
      unawaited(
        _crashlytics.setContext(
          screen: 'create_flight_map_preview',
          routeLengthKm: route.distanceInKm.round(),
          mapDetail: state.selectedMapDetailLevel.name,
        ),
      );
      if (_isAntimeridianRoute(route)) {
        unawaited(
          _analytics.log(
            SearchRouteNotSupportedEvent(
              reason: 'antimeridian',
              routeLengthKm: route.distanceInKm,
            ),
          ),
        );
        unawaited(
          _crashlytics.setContext(screen: 'create_flight_route_not_supported'),
        );
        emit(
          state.copyWith(
            step: CreateFlightStep.routeNotSupported,
            flightRoute: route,
            isPreviewLoading: false,
            isWikiSuggestionsLoading: false,
            isOverviewLoading: false,
            isTooLongFlight: true,
            flightInfo: FlightInfo.empty,
            articleCandidates: const [],
            clearSelectedArticleUrls: true,
            errorMessage: t.createFlight.mapPreview.routeNotSupportedMsg,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          flightRoute: route,
          isPreviewLoading: false,
          isTooLongFlight: false,
          hasInternetForMapPreview: true,
          flightInfo: FlightInfo.empty,
          articleCandidates: const [],
          clearSelectedArticleUrls: true,
          isWikiSuggestionsLoading: true,
          isOverviewLoading: true,
        ),
      );

      unawaited(_prefetchOverview(route));
    } catch (e, stackTrace) {
      _logger.error('Failed to prepare map preview: $e');
      unawaited(
        _crashlytics.recordError(
          e,
          stackTrace,
          reason: 'prepare_preview_failed',
        ),
      );
      emit(
        state.copyWith(
          isPreviewLoading: false,
          isWikiSuggestionsLoading: false,
          isOverviewLoading: false,
          errorMessage: t.createFlight.errors.failedBuildPreview,
        ),
      );
    }
  }

  Future<void> _prefetchOverview(FlightRoute route) async {
    try {
      final info = await _getFlightInfoUseCase.call(
        airportArrival: route.arrival.name,
        airportDeparture: route.departure.name,
        waypoints: route.waypoints,
      );

      final currentRoute = state.flightRoute;
      if (currentRoute == null || currentRoute.routeCode != route.routeCode) {
        return;
      }

      final updatedCandidates = _safeBuildArticleCandidates(info: info);
      _logger.log(
        'Local wiki candidates from overview=${updatedCandidates.length}',
      );
      emit(
        state.copyWith(
          flightInfo: info,
          isOverviewLoading: false,
          isWikiSuggestionsLoading: true,
        ),
      );
    } catch (e) {
      _logger.error('Failed to prefetch route overview: $e');
      emit(
        state.copyWith(
          isOverviewLoading: false,
          isWikiSuggestionsLoading: false,
          errorMessage: t.createFlight.errors.overviewUnavailableContinue,
        ),
      );
      return;
    }

    try {
      final suggestedCandidates = await _getFlightInfoUseCase
          .getWikiArticleCandidates(
            airportArrival: route.arrival.name,
            airportDeparture: route.departure.name,
            waypoints: route.waypoints,
          );
      _logger.log(
        'Backend wiki candidates received=${suggestedCandidates.length}',
      );
      if (suggestedCandidates.isNotEmpty) {
        final sample = suggestedCandidates.take(3).map((e) => e.url).join(', ');
        _logger.log('Backend wiki sample=[$sample]');
      }

      final routeAfterWikiCall = state.flightRoute;
      if (routeAfterWikiCall == null ||
          routeAfterWikiCall.routeCode != route.routeCode) {
        _logger.log(
          'Skip applying backend wiki candidates due to route mismatch',
        );
        return;
      }

      emit(
        state.copyWith(
          articleCandidates: suggestedCandidates,
          selectedArticleUrls: _retainSelectedArticleUrls(
            selectedUrls: state.selectedArticleUrls,
            candidates: suggestedCandidates,
          ),
          isWikiSuggestionsLoading: false,
        ),
      );
      _logger.log(
        'Applied backend wiki candidates to state: ${suggestedCandidates.length}',
      );
    } catch (e) {
      _logger.error('Failed to fetch wiki article suggestions: $e');
      emit(state.copyWith(isWikiSuggestionsLoading: false));
    }
  }

  List<WikiArticleCandidate> _buildArticleCandidates({
    required FlightInfo info,
  }) {
    return _buildWikipediaCandidatesUseCase.call(flightInfo: info);
  }

  List<WikiArticleCandidate> _safeBuildArticleCandidates({
    required FlightInfo info,
  }) {
    try {
      return _buildArticleCandidates(info: info);
    } catch (e) {
      _logger.error('Failed to build article candidates: $e');
      return const [];
    }
  }

  List<String> _retainSelectedArticleUrls({
    required List<String> selectedUrls,
    required List<WikiArticleCandidate> candidates,
  }) {
    final candidateUrls = candidates.map((candidate) => candidate.url).toSet();
    return selectedUrls.where(candidateUrls.contains).toList();
  }

  List<Airport> _applyStepAirportFilter(List<Airport> airports) {
    if (state.step != CreateFlightStep.arrival) return airports;

    final departureCode = _airportCode(state.selectedDeparture);
    if (departureCode.isEmpty) return airports;

    return airports
        .where((airport) => _airportCode(airport) != departureCode)
        .toList();
  }

  bool _sameAirportAsDeparture(Airport airport) {
    final departureCode = _airportCode(state.selectedDeparture);
    if (departureCode.isEmpty) return false;
    return _airportCode(airport) == departureCode;
  }

  Future<void> _touchFavoriteIfNeeded(Airport airport) async {
    final code = _airportCode(airport);
    if (code.isEmpty) return;

    final isFavorite = await _favoritesRepository.isFavorite(code);
    if (!isFavorite) return;
    await _favoritesRepository.touchFavorite(code);
    await _refreshFavorites();
  }

  Future<bool> _isFavorite(Airport? airport) async {
    final code = _airportCode(airport);
    if (code.isEmpty) return false;
    return _favoritesRepository.isFavorite(code);
  }

  Future<void> _refreshFavorites() async {
    final favoriteAirports = await _loadFavoriteAirports();
    emit(state.copyWith(favoriteAirports: favoriteAirports));
  }

  Future<List<Airport>> _loadFavoriteAirports() async {
    final favoriteCodes = await _favoritesRepository.getFavoriteCodes();
    final airports = <Airport>[];
    for (final code in favoriteCodes) {
      final airport = _airportsDb.findByCode(code);
      if (airport != null) {
        airports.add(airport);
      }
    }
    return airports;
  }

  String _airportCode(Airport? airport) {
    if (airport == null) return '';
    final primary = airport.primaryCode.trim().toUpperCase();
    if (primary.isNotEmpty) return primary;
    return airport.displayCode.trim().toUpperCase();
  }

  bool _isAntimeridianRoute(FlightRoute route) {
    final points = route.waypoints.length >= 2
        ? route.waypoints
        : [route.departure.latLon, route.arrival.latLon];
    for (var i = 1; i < points.length; i++) {
      final deltaLon = points[i].longitude - points[i - 1].longitude;
      if (deltaLon.abs() > 180) {
        return true;
      }
    }
    return false;
  }

  String _airportSearchLabel(Airport airport) =>
      '${airport.name} (${airport.displayCode})';

  String _articleBundleId(FlightRoute route) =>
      '${route.routeCode}_${route.departure.displayCode}_${route.arrival.displayCode}';

  @override
  Future<void> close() {
    _downloadCancelled = true;
    _downloadWikipediaArticlesUseCase.cancel();
    _downloadMapUseCase.cancel();
    _downloadSubscription?.cancel();
    return super.close();
  }
}
