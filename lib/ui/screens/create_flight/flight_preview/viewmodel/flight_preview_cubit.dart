import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';
import 'package:latlong2/latlong.dart';

/// Cubit for managing create_flight map preview state
class FlightPreviewCubit extends Cubit<FlightPreviewState> {
  final FlightPreviewAirports params;
  final FlightRouteProvider _routeProvider;
  final DownloadMapUseCase downloadMapUseCase;
  final GetFlightInfoUseCase getFlightInfoUseCase;
  final GetFlightInfoUseCase _getFlightInfoUseCase;

  StreamSubscription? _downloadSubscription;

  final _logger = Logger('FlightPreviewCubit');

  FlightPreviewCubit({
    required this.params,
    required FlightRouteProvider routeProvider,
    required this.downloadMapUseCase,
    required this.getFlightInfoUseCase,
  }) : _routeProvider = routeProvider,
       _getFlightInfoUseCase = getFlightInfoUseCase,
       super(const FlightMapPreviewLoading()) {
    _initialize(params);
  }

  /// Initialize the cubit and calculate route/corridor
  Future<void> _initialize(FlightPreviewParams params) async {
    emit(const FlightMapPreviewLoading());

    try {
      switch (params) {
        case FlightPreviewAirports():
          await _calculateRouteAndCorridor(params);
          break;
      }
    } catch (e) {
      emit(FlightMapPreviewError('Error initializing: $e'));
    }
  }

  /// Calculate route and corridor based on departure and arrival airports
  Future<void> _calculateRouteAndCorridor(
    FlightPreviewAirports airports,
  ) async {
    try {
      final route = _routeProvider.getRoute(
        departure: airports.departure,
        arrival: airports.arrival,
      );

      final zoomLevel = MapUtils.calculateZoomLevel(
        departure: airports.departure,
        arrival: airports.arrival,
      );

      final isTooLong = route.distanceInKm > 5000.0;

      if (!isTooLong) {
        unawaited(_loadFlightOverview(route));
      }
      emit(
        FlightMapPreviewLoaded(
          flightRoute: route,
          flightInfo: isTooLong
              ? FlightInfo(
                  'Right now, flights longer than 5,000 km aren’t calculated as accurately as we’d like - but we’re working hard to make sure long flights are supported soon!',
                  [],
                )
              : FlightInfo.empty,
          currentZoom: zoomLevel,
          isTooLongFlight: isTooLong,
        ),
      );
    } catch (e) {
      _logger.error(e);
      emit(FlightMapPreviewError('Error during flight preview'));
    }
  }

  Future<void> _loadFlightOverview(FlightRoute route) async {
    try {
      final flightInfo = await _getFlightInfoUseCase.call(
        airportArrival: route.arrival.name,
        airportDeparture: route.departure.name,
        waypoints: route.waypoints,
      );
      _logger.log('Flight overview: ${flightInfo.overview}');
      final currentState = state;
      if (currentState is FlightMapPreviewLoaded && !isClosed) {
        emit(currentState.copyWith(flightInfo: flightInfo));
      }
    } catch (e) {
      _logger.error('_loadPoi error: $e');
    }
  }

  /// Update zoom level
  void updateZoom(double zoom) {
    final currentState = state;
    if (currentState is FlightMapPreviewLoaded) {
      emit(currentState.copyWith(currentZoom: zoom));
    }
  }

  /// Start the download process
  void startDownload() async {
    try {
      final currentState = state as FlightMapPreviewLoaded;

      // Reset state and start creation phase
      emit(MapDownloadingState(progress: 0.0));
      _logger.log('flightInfo (to save): ${currentState.flightInfo}');

      // Initialize offline manager
      _downloadSubscription = downloadMapUseCase
          .call(
            flightRoute: currentState.flightRoute,
            flightInfo: currentState.flightInfo,
          )
          .listen((event) {
            // Handle different download events
            switch (event) {
              case DownloadMapProgress():
                // Update download progress
                emit(MapDownloadingState(progress: event.progress));
                break;
              case DownloadMapDone():
                // Download completed successfully
                emit(MapDownloadingState(progress: 1.0));
                Future.delayed(Duration(seconds: 2), () {
                  if (!isClosed) {
                    emit(MapDownloadingState(progress: 1.0, done: true));
                  }
                });
                break;
              case DownloadMapError():
                // Handle error
                emit(
                  MapDownloadingState(
                    progress: 0.0,
                    errorMessage: event.errorMsg,
                  ),
                );
                break;
              case DownloadMapInitializing():
                // Start download process
                emit(MapDownloadingState(progress: 0.0));
                break;
              case DownloadMapComputingTiles():
                // Computing tiles - keep current progress
                break;
              case DownloadMapStartingWorkers():
                // Starting workers - keep current progress
                break;
              case DownloadMapFinalizing():
                // Finalizing - keep current progress
                break;
              case DownloadMapVerifying():
                // Verifying - keep current progress
                break;
            }
          });
    } catch (e) {
      emit(
        MapDownloadingState(
          progress: 0.0,
          errorMessage: 'Failed to start download: $e',
        ),
      );
    }
  }

  /// Cancel download
  void cancelDownload() {
    downloadMapUseCase.cancel();
    _downloadSubscription?.cancel();
    _downloadSubscription = null;
    _calculateRouteAndCorridor(params);
  }

  /// Retry initialization (public method for error recovery)
  void retry() {
    _initialize(params);
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }

  /// Get center point between airports
  LatLng get center =>
      MapUtils.center(departure: params.departure, arrival: params.arrival);
}
