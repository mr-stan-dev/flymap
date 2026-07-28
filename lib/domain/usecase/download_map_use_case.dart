import 'dart:async';

import 'package:flymap/logger.dart';
import 'package:path/path.dart' as p;

import 'package:equatable/equatable.dart';
import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/data/tiles_downloader/vector_tiles_downloader.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_map.dart';
import 'package:flymap/domain/entity/flight_operational_data.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/map_download_config.dart';
import 'package:uuid/uuid.dart';

sealed class DownloadMapEvent extends Equatable {
  const DownloadMapEvent();
}

class DownloadMapProgress extends DownloadMapEvent {
  final double progress;
  final int downloadedBytes;

  const DownloadMapProgress(this.progress, {required this.downloadedBytes});

  @override
  List<Object?> get props => [progress, downloadedBytes];
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
  final ConnectivityChecker _connectivity;
  final _logger = Logger('DownloadMapUseCase');
  VectorTilesDownloader? _currentDownloader;
  static const Uuid _uuid = Uuid();

  DownloadMapUseCase({
    required FlightsDBService service,
    required ConnectivityChecker connectivity,
  }) : _flightsService = service,
       _connectivity = connectivity;

  void cancel() {
    _currentDownloader?.cancel();
  }

  static String newFlightId() => _uuid.v4();

  /// Map files are owned by ONE flight: the flightId in the name guarantees
  /// two flights on the same airport pair (which can have different real
  /// tracks and corridors) never share or overwrite each other's map.
  /// Legacy files without a flightId are still resolved via the stored
  /// [FlightMap.filePath] and protected by FlightAssetsDeleter refcounting.
  static String mapFileName({
    required FlightRoute route,
    required String flightId,
  }) {
    return '${route.routeCode}_${flightId}_${MapDownloadConfig.mapLayerId}';
  }

  Stream<DownloadMapEvent> call({
    required String flightId,
    required FlightRoute flightRoute,
    required FlightInfo flightInfo,
    FlightOperationalData? flightOperationalData,
    FlightSchedule? flightSchedule,
    required String flightAccessTier,
    required int maxZoom,
  }) async* {
    try {
      // Check internet connectivity before starting
      if (!await _connectivity.hasInternetConnectivity()) {
        yield const DownloadMapError(
          'No internet connection. Please check your connection and try again.',
        );
        return;
      }

      // Create and start the vector tiles downloader
      final downloader = VectorTilesDownloader(
        polygons: flightRoute.effectiveCorridorPolygons,
        minZoom: MapDownloadConfig.minDownloadZoom,
        maxZoom: maxZoom,
      );
      _currentDownloader = downloader;

      final mapLayer = MapDownloadConfig.mapLayerId;
      final fileName = mapFileName(route: flightRoute, flightId: flightId);

      // Forward the download stream and handle completion
      await for (final event in downloader.download(fileName)) {
        if (event is DownloadMapDone) {
          // Store only the filename — absolute paths break on iOS when
          // the container UUID changes between launches.
          final mapData = FlightMap(
            layer: mapLayer,
            sizeBytes: event.fileSize,
            downloadedAt: DateTime.now(),
            filePath: p.basename(event.filePath),
          );

          final result = await _saveFlightData(
            flightId: flightId,
            flightMap: mapData,
            flightRoute: flightRoute,
            flightInfo: flightInfo,
            flightOperationalData: flightOperationalData,
            flightSchedule: flightSchedule,
            flightAccessTier: flightAccessTier,
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
    FlightOperationalData? flightOperationalData,
    FlightSchedule? flightSchedule,
    required String flightAccessTier,
  }) async {
    _logger.log(
      "_saveFlightData start: id='$flightId', mapPath='${flightMap.filePath}', mapSize=${flightMap.sizeBytes}, route='${flightRoute.routeCode}', infoEmpty=${flightInfo.isEmpty}",
    );
    try {
      final flight = Flight(
        id: flightId,
        route: flightRoute,
        maps: [flightMap],
        routeInsights: flightInfo.routeInsights,
        offlineContent: flightInfo.offlineContent,
        timestamp: FlightTimestamp(createdAt: DateTime.now()),
        flightAccessTier: flightAccessTier,
        operationalData: flightOperationalData,
        schedule: flightSchedule,
      );
      _logger.log('Inserting flight into DB: id=${flight.id}');
      await _flightsService.saveOrUpdateFlight(flight);
      _logger.log("Flight saved successfully: '${flight.id}'");
      _logger.log('Flight map path: ${flightMap.filePath}');
      return Result.success(flight: flight);
    } catch (e) {
      _logger.error('Failed to save flight data: $e');
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
