import 'dart:async';

import 'package:flymap/data/great_circle_route_provider.dart';
import 'package:flymap/data/route_corridor_provider.dart';
import 'package:flymap/entity/flight_preview.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

class FlightPreviewCubit extends Cubit<FlightPreviewState> {
  final FlightPreviewAirports params;
  final DownloadMapUseCase downloadMapUseCase;

  StreamSubscription? _downloadSubscription;

  FlightPreviewCubit({required this.params, required this.downloadMapUseCase})
    : super(const FlightMapPreviewLoading()) {
    _initialize(params);
  }

  /// Initialize the cubit and calculate route/corridor
  Future<void> _initialize(FlightPreviewParams params) async {
    emit(const FlightMapPreviewLoading());

    try {
      switch (params) {
        case FlightPreviewAirports():
          await _calculateRouteAndCorridor(params);
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
      // Generate great circle route
      final routeProvider = GreatCircleRouteProvider();
      final route = routeProvider.calculateRoute(
        airports.departure.latLon,
        airports.arrival.latLon,
      );

      // Generate corridor
      final corridorProvider = RouteCorridorProvider();
      final corridor = corridorProvider.calculateCorridor(
        route,
        widthKm: 100.0,
      );

      // Calculate appropriate zoom level
      final zoomLevel = MapUtils.calculateZoomLevel(
        departure: airports.departure,
        arrival: airports.arrival,
      );

      // Calculate route length (km) using MapUtils (Haversine)
      final routeDistanceKm = MapUtils.distance(
        departure: airports.departure,
        arrival: airports.arrival,
      );
      final isTooLong = routeDistanceKm > 5000.0;

      emit(
        FlightMapPreviewLoaded(
          flightPreview: FlightPreview(
            departure: airports.departure,
            arrival: airports.arrival,
            waypoints: route,
            corridor: corridor,
          ),
          currentZoom: zoomLevel,
          isTooLongFlight: isTooLong,
        ),
      );
    } catch (e) {
      emit(FlightMapPreviewError('Error calculating route: $e'));
    }
  }

  /// Update zoom level
  void updateZoom(double zoom) {
    final currentState = state;
    if (currentState is FlightMapPreviewLoaded) {
      emit(
        FlightMapPreviewLoaded(
          flightPreview: currentState.flightPreview,
          currentZoom: zoom,
          isTooLongFlight: currentState.isTooLongFlight,
        ),
      );
    }
  }

  /// Start the download process
  void startDownload() async {
    try {
      // Reset state and start creation phase
      emit(MapDownloadingState(progress: 0.0));

      // Initialize offline manager
      _downloadSubscription = downloadMapUseCase
          .call(departure: params.departure, arrival: params.arrival)
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
