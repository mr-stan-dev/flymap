import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flymap/data/great_circle_route_provider.dart';
import 'package:flymap/data/local/flights_local_db_service.dart';
import 'package:flymap/data/route_corridor_provider.dart';
import 'package:flymap/data/tiles_downloader/vector_tiles_downloader.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/map/flight_map.dart';
import 'package:latlong2/latlong.dart';

import '../logger.dart';

sealed class DownloadMapEvent extends Equatable {
  const DownloadMapEvent();
}

class DownloadMapProgress extends DownloadMapEvent {
  final double progress;

  const DownloadMapProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

class DownloadMapDone extends DownloadMapEvent {
  final String filePath;

  const DownloadMapDone(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class DownloadMapError extends DownloadMapEvent {
  final String errorMsg;

  const DownloadMapError(this.errorMsg);

  @override
  List<Object?> get props => [errorMsg];
}

class DownloadMapInitializing extends DownloadMapEvent {
  const DownloadMapInitializing();

  @override
  List<Object?> get props => [];
}

class DownloadMapComputingTiles extends DownloadMapEvent {
  final int totalTiles;

  const DownloadMapComputingTiles(this.totalTiles);

  @override
  List<Object?> get props => [totalTiles];
}

class DownloadMapStartingWorkers extends DownloadMapEvent {
  final int workerCount;

  const DownloadMapStartingWorkers(this.workerCount);

  @override
  List<Object?> get props => [workerCount];
}

class DownloadMapFinalizing extends DownloadMapEvent {
  const DownloadMapFinalizing();

  @override
  List<Object?> get props => [];
}

class DownloadMapVerifying extends DownloadMapEvent {
  const DownloadMapVerifying();

  @override
  List<Object?> get props => [];
}

class DownloadMapUseCase {
  final FlightsLocalDBService _flightsService;
  final _logger = Logger('DownloadMapUseCase');
  VectorTilesDownloader? _currentDownloader;

  DownloadMapUseCase({required FlightsLocalDBService service})
    : _flightsService = service;

  static const double defaultWidthKm = 100;

  void cancel() {
    _currentDownloader?.cancel();
  }

  Stream<DownloadMapEvent> call({
    required Airport departure,
    required Airport arrival,
    required FlightInfo flightInfo,
  }) async* {
    try {
      // Generate route and corridor
      final route = GreatCircleRouteProvider().calculateRoute(
        departure.latLon,
        arrival.latLon,
      );
      final corridor = RouteCorridorProvider().calculateCorridor(
        route,
        widthKm: defaultWidthKm,
      );

      // Create and start the vector tiles downloader
      final downloader = VectorTilesDownloader(
        polygon: corridor,
        minZoom: 0,
        maxZoom: 10,
      );
      _currentDownloader = downloader;

      // Forward the download stream and handle completion
      await for (final event in downloader.download()) {
        if (event is DownloadMapDone) {
          // Save flight data with the MBTiles file
          final result = await _saveFlightData(
            localFilePath: event.filePath,
            departure: departure,
            arrival: arrival,
            route: route,
            corridor: corridor,
            flightInfo: flightInfo,
          );

          if (result.isSuccess) {
            yield event;
          } else {
            yield DownloadMapError(result.error!);
          }
        } else {
          // Forward all other events
          yield event;
        }
      }
    } catch (e) {
      yield DownloadMapError('Unexpected error: $e');
    }
  }

  Future<Result> _saveFlightData({
    required String localFilePath,
    required Airport departure,
    required Airport arrival,
    required List<LatLng> route,
    required List<LatLng> corridor,
    required FlightInfo flightInfo,
  }) async {
    try {
      final mapFile = File(localFilePath);
      final mapSizeBytes = await mapFile.length();

      final mapData = FlightMap(
        layer: 'openfreemap_vector',
        sizeBytes: mapSizeBytes,
        downloadedAt: DateTime.now(),
        filePath: localFilePath,
      );

      final id =
          '${departure.code}_${arrival.code}_${DateTime.now().millisecondsSinceEpoch}';
      final flight = Flight(
        id: id,
        departure: departure,
        arrival: arrival,
        waypoints: route,
        corridor: corridor,
        maps: [mapData],
        flightInfo: flightInfo,
      );

      await _flightsService.insertFlight(flight);

      _logger.log('Flight saved successfully: \'${flight.id}\'');
      _logger.log('Flight info: $flightInfo');
      return Result.success(flight: flight);
    } catch (e) {
      return Result.error('Failed to save flight data: $e');
    }
  }
}

// Simple result class for better error handling
class Result {
  final bool isSuccess;
  final String? error;
  final Flight? flight;

  const Result._({required this.isSuccess, this.error, this.flight});

  factory Result.success({Flight? flight}) =>
      Result._(isSuccess: true, flight: flight);

  factory Result.error(String error) =>
      Result._(isSuccess: false, error: error);
}
