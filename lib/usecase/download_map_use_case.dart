import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/data/route/great_circle_route_provider.dart';
import 'package:flymap/data/route/route_corridor_provider.dart';
import 'package:flymap/data/tiles_downloader/vector_tiles_downloader.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_map.dart';
import 'package:flymap/entity/flight_route.dart';
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
  final int fileSize;

  const DownloadMapDone(this.filePath, this.fileSize);

  @override
  List<Object?> get props => [filePath, fileSize];
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
  final FlightsDBService _flightsService;
  final _logger = Logger('DownloadMapUseCase');
  VectorTilesDownloader? _currentDownloader;

  DownloadMapUseCase({required FlightsDBService service})
    : _flightsService = service;

  void cancel() {
    _currentDownloader?.cancel();
  }

  Stream<DownloadMapEvent> call({
    required FlightRoute flightRoute,
    required FlightInfo flightInfo,
  }) async* {
    try {
      // Create and start the vector tiles downloader
      final downloader = VectorTilesDownloader(
        polygon: flightRoute.corridor,
        minZoom: 0,
        maxZoom: 10,
      );
      _currentDownloader = downloader;

      final id =
          '${flightRoute.routeCode}_${DateTime.now().millisecondsSinceEpoch}';
      final mapLayer = 'ofm_vector'; // openfreemap_vector
      final fileName = '${flightRoute.routeCode}_$mapLayer';

      // Forward the download stream and handle completion
      await for (final event in downloader.download(fileName)) {
        if (event is DownloadMapDone) {
          // Save flight data with the MBTiles file
          final mapData = FlightMap(
            layer: mapLayer,
            sizeBytes: event.fileSize,
            downloadedAt: DateTime.now(),
            filePath: event.filePath,
          );

          final result = await _saveFlightData(
            flightId: id,
            flightMap: mapData,
            flightRoute: flightRoute,
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
    required String flightId,
    required FlightMap flightMap,
    required FlightRoute flightRoute,
    required FlightInfo flightInfo,
  }) async {
    try {
      final flight = Flight(
        id: flightId,
        route: flightRoute,
        maps: [flightMap],
        info: flightInfo,
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
