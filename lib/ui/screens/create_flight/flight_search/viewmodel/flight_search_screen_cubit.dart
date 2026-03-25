import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/popular_flights.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';

class FlightSearchScreenCubit extends Cubit<FlightSearchScreenState> {
  FlightSearchScreenCubit({
    required AirportsDatabase airportsDb,
    required FavoriteAirportsRepository favoritesRepository,
    required FlightRouteProvider routeProvider,
    required DownloadMapUseCase downloadMapUseCase,
    required GetFlightInfoUseCase getFlightInfoUseCase,
  }) : _airportsDb = airportsDb,
       _favoritesRepository = favoritesRepository,
       _routeProvider = routeProvider,
       _downloadMapUseCase = downloadMapUseCase,
       _getFlightInfoUseCase = getFlightInfoUseCase,
       super(FlightSearchScreenState.initial()) {
    _initialize();
  }

  final _logger = Logger('FlightSearchScreenCubit');
  final AirportsDatabase _airportsDb;
  final FavoriteAirportsRepository _favoritesRepository;
  final FlightRouteProvider _routeProvider;
  final DownloadMapUseCase _downloadMapUseCase;
  final GetFlightInfoUseCase _getFlightInfoUseCase;

  StreamSubscription? _downloadSubscription;

  static const _tooLongRouteMessage =
      'Downloading routes over 5,000 km is not supported yet.';

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
        state.copyWith(
          errorMessage: 'Failed to load airports. Please try again.',
        ),
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
          errorMessage: 'Airport search failed. Try another query.',
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
            flightInfo: FlightInfo.empty,
            isPreviewLoading: false,
            isOverviewLoading: false,
            isTooLongFlight: false,
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
            flightInfo: FlightInfo.empty,
            isPreviewLoading: false,
            isOverviewLoading: false,
            isTooLongFlight: false,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        break;
      case CreateFlightStep.mapPreview:
      case CreateFlightStep.overview:
        break;
    }
  }

  Future<void> toggleFavoriteForSelectedAirport() async {
    final airport = switch (state.step) {
      CreateFlightStep.departure => state.selectedDeparture,
      CreateFlightStep.arrival => state.selectedArrival,
      CreateFlightStep.mapPreview || CreateFlightStep.overview => null,
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
      CreateFlightStep.mapPreview || CreateFlightStep.overview => null,
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
            clearErrorMessage: true,
          ),
        );
        break;
      case CreateFlightStep.mapPreview:
      case CreateFlightStep.overview:
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
            flightInfo: FlightInfo.empty,
            isPreviewLoading: false,
            isOverviewLoading: false,
            isTooLongFlight: false,
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
            flightInfo: FlightInfo.empty,
            isPreviewLoading: true,
            isOverviewLoading: false,
            isTooLongFlight: false,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        await _preparePreview();
        break;
      case CreateFlightStep.mapPreview:
      case CreateFlightStep.overview:
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

  Future<void> startDownload() async {
    if (state.isDownloading) return;
    final route = state.flightRoute;
    if (route == null || state.isTooLongFlight) return;

    _downloadSubscription?.cancel();
    emit(
      state.copyWith(
        isDownloading: true,
        downloadProgress: 0.0,
        downloadedBytes: 0,
        downloadStage: DownloadStage.initializing,
        clearDownloadTileCount: true,
        clearDownloadWorkerCount: true,
        downloadDone: false,
        clearDownloadErrorMessage: true,
        clearErrorMessage: true,
      ),
    );

    _downloadSubscription = _downloadMapUseCase
        .call(flightRoute: route, flightInfo: state.flightInfo)
        .listen((event) {
          switch (event) {
            case DownloadMapProgress():
              emit(
                state.copyWith(
                  isDownloading: true,
                  downloadProgress: event.progress,
                  downloadedBytes: event.downloadedBytes,
                  downloadStage: DownloadStage.downloading,
                  downloadDone: false,
                ),
              );
              break;
            case DownloadMapDone():
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
              emit(
                state.copyWith(
                  isDownloading: false,
                  downloadStage: DownloadStage.failed,
                  downloadErrorMessage: event.errorMsg,
                ),
              );
              break;
            case DownloadMapInitializing():
              emit(
                state.copyWith(
                  isDownloading: true,
                  downloadProgress: 0.0,
                  downloadedBytes: 0,
                  downloadStage: DownloadStage.initializing,
                  downloadDone: false,
                  clearDownloadTileCount: true,
                  clearDownloadWorkerCount: true,
                  clearDownloadErrorMessage: true,
                ),
              );
              break;
            case DownloadMapComputingTiles():
              emit(
                state.copyWith(
                  isDownloading: true,
                  downloadStage: DownloadStage.computingTiles,
                  downloadTileCount: event.totalTiles,
                ),
              );
              break;
            case DownloadMapStartingWorkers():
              emit(
                state.copyWith(
                  isDownloading: true,
                  downloadStage: DownloadStage.startingWorkers,
                  downloadWorkerCount: event.workerCount,
                ),
              );
              break;
            case DownloadMapFinalizing():
              emit(
                state.copyWith(
                  isDownloading: true,
                  downloadStage: DownloadStage.finalizing,
                ),
              );
              break;
            case DownloadMapVerifying():
              emit(
                state.copyWith(
                  isDownloading: true,
                  downloadStage: DownloadStage.verifying,
                ),
              );
              break;
          }
        });
  }

  void cancelDownload() {
    if (!state.isDownloading) return;
    _downloadMapUseCase.cancel();
    _downloadSubscription?.cancel();
    emit(
      state.copyWith(
        isDownloading: false,
        downloadStage: DownloadStage.idle,
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
            clearErrorMessage: true,
          ),
        );
        return false;
      case CreateFlightStep.mapPreview:
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
    }
  }

  Future<void> _preparePreview() async {
    final departure = state.selectedDeparture;
    final arrival = state.selectedArrival;
    if (departure == null || arrival == null) return;

    try {
      final route = _routeProvider.getRoute(
        departure: departure,
        arrival: arrival,
      );
      final isTooLong = route.distanceInKm > 5000.0;

      emit(
        state.copyWith(
          flightRoute: route,
          isPreviewLoading: false,
          isTooLongFlight: isTooLong,
          flightInfo: isTooLong
              ? const FlightInfo(_tooLongRouteMessage, [])
              : FlightInfo.empty,
          isOverviewLoading: !isTooLong,
        ),
      );

      if (!isTooLong) {
        unawaited(_prefetchOverview(route));
      }
    } catch (e) {
      _logger.error('Failed to prepare map preview: $e');
      emit(
        state.copyWith(
          isPreviewLoading: false,
          isOverviewLoading: false,
          errorMessage: 'Failed to build route preview. Please try again.',
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

      emit(state.copyWith(flightInfo: info, isOverviewLoading: false));
    } catch (e) {
      _logger.error('Failed to prefetch route overview: $e');
      emit(
        state.copyWith(
          isOverviewLoading: false,
          errorMessage:
              'Could not load route overview. You can still continue.',
        ),
      );
    }
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

  String _airportSearchLabel(Airport airport) =>
      '${airport.name} (${airport.displayCode})';

  @override
  Future<void> close() {
    _downloadMapUseCase.cancel();
    _downloadSubscription?.cancel();
    return super.close();
  }
}
