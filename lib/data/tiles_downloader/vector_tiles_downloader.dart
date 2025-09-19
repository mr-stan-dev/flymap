import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flymap/data/tiles_downloader/mbtiles_verifier.dart';
import 'package:flymap/data/tiles_downloader/sea_tiles_filter.dart';
import 'package:flymap/data/tiles_downloader/tile_utils.dart';
import 'package:flymap/data/tiles_downloader/vector_tiles_db.dart';
import 'package:flymap/data/tiles_downloader/vector_tiles_worker.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class VectorTilesDownloader {
  final List<LatLng> polygon;
  final int minZoom;
  final int maxZoom;
  final int isolatesCount;
  final _logger = Logger('VectorTilesDownloader');

  VectorTilesDownloader({
    required this.polygon,
    required this.minZoom,
    required this.maxZoom,
    this.isolatesCount = 6,
  });

  static const _urlTemplate =
      'https://tiles.openfreemap.org/planet/20250730_001001_pt/{z}/{x}/{y}.pbf';

  final List<Isolate> _isolates = [];
  bool _canceled = false;
  StreamController<DownloadMapEvent>? _controllerRef;

  void cancel() {
    _canceled = true;
    for (final iso in _isolates) {
      iso.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _controllerRef?.add(const DownloadMapError('Canceled'));
    _controllerRef?.close();
  }

  Stream<DownloadMapEvent> download(String fileName) {
    final controller = StreamController<DownloadMapEvent>();
    _controllerRef = controller;
    _performDownload(fileName, controller);
    return controller.stream;
  }

  Future<void> _performDownload(
    String fileName,
    StreamController<DownloadMapEvent> controller,
  ) async {
    Database? db;
    ReceivePort? receivePort;
    try {
      if (_canceled) {
        controller.add(const DownloadMapError('Canceled'));
        controller.close();
        return;
      }

      _logger.log(
        'Starting download for polygon with ${polygon.length} points, zoom $minZoom-$maxZoom',
      );

      // Initializing
      controller.add(const DownloadMapInitializing());

      // Get proper directory path
      final appDir = await getApplicationCacheDirectory();
      final targetDirPath = p.join(appDir.path, 'mbtiles');

      final mbtilesPath = p.join(targetDirPath, '$fileName.mbtiles');
      _logger.log('MBTiles file: $mbtilesPath');

      // Ensure target directory exists
      final targetDirectory = Directory(targetDirPath);
      if (!await targetDirectory.exists()) {
        _logger.log('Creating target directory: $targetDirPath');
        await targetDirectory.create(recursive: true);
      }

      // Create database using sqflite
      final dbHelper = VectorTilesDb();
      db = await openDatabase(
        mbtilesPath,
        version: 1,
        onCreate: dbHelper.createMbtilesSchema,
      );

      if (_canceled) {
        await db.close();
        controller.add(const DownloadMapError('Canceled'));
        controller.close();
        return;
      }

      // Compute all tiles
      final allTiles = <MapTile>[];
      for (int z = minZoom; z <= maxZoom; z++) {
        allTiles.addAll(TileUtils.tilesForPolygon(polygon, z));
      }

      // Filter out sea tiles for zoom >= 6
      final seaFilter = SeaTilesFilter(minZoomToFilter: 6);
      final filteredTiles = seaFilter.filterTiles(allTiles);
      final skipped = allTiles.length - filteredTiles.length;
      _logger.log(
        'Computed ${allTiles.length} tiles; skipped $skipped sea tiles; downloading ${filteredTiles.length} tiles',
      );

      // Computing tiles event
      controller.add(DownloadMapComputingTiles(filteredTiles.length));

      // Split tiles into chunks
      final chunks = _splitList(filteredTiles, isolatesCount);
      _logger.log(
        'Split into ${chunks.length} chunks with ${isolatesCount} isolates',
      );

      // Starting workers event
      controller.add(DownloadMapStartingWorkers(chunks.length));

      // Receive port for worker communication
      receivePort = ReceivePort();
      final totalWorkers = chunks.length;
      int completed = 0;
      int tilesDownloaded = 0;
      final completer = Completer<void>();
      final tileQueue = <TileData>[];
      bool isProcessingQueue = false;

      // Process tile queue sequentially to avoid database conflicts
      Future<void> processTileQueue() async {
        if (isProcessingQueue) return;
        isProcessingQueue = true;

        while (tileQueue.isNotEmpty) {
          if (_canceled) {
            isProcessingQueue = false;
            return;
          }
          final tile = tileQueue.removeAt(0);
          try {
            // Check if database is still open
            if (db == null || !db.isOpen) {
              _logger.log('Database is closed, skipping tile insertion');
              break;
            }
            await dbHelper.insertTile(
              db,
              TileRecord(tile.z, tile.x, tile.y, tile.bytes),
            );
            tilesDownloaded++;

            // Log progress updates every 50 tiles
            if (tilesDownloaded % 50 == 0) {
              final progress = tilesDownloaded / filteredTiles.length;
              controller.add(DownloadMapProgress(progress));
              _logger.log(
                'Downloaded $tilesDownloaded/${filteredTiles.length} tiles (${(tilesDownloaded / filteredTiles.length * 100).toStringAsFixed(1)}%)',
              );
            }
          } catch (e) {
            _logger.error('Error inserting tile: $e');
          }
        }
        isProcessingQueue = false;
      }

      // Wait for queue to be completely empty
      Future<void> waitForQueueEmpty() async {
        int waitCount = 0;
        while (tileQueue.isNotEmpty || isProcessingQueue) {
          if (_canceled) return;
          waitCount++;
          if (waitCount % 20 == 0) {
            // Log every second
            _logger.log(
              'Waiting for queue to empty: ${tileQueue.length} tiles remaining, processing: $isProcessingQueue',
            );
          }
          await Future.delayed(Duration(milliseconds: 50));
        }
        _logger.log('Queue is now empty');
      }

      receivePort.listen((message) async {
        if (_canceled) return;
        if (message is TileData) {
          // Add to queue and process
          tileQueue.add(message);
          await processTileQueue();
        } else if (message == 'done') {
          completed++;
          _logger.log('Worker $completed/$totalWorkers completed');
          if (completed == totalWorkers) {
            _logger.log('All workers completed. Finalizing...');
            controller.add(const DownloadMapFinalizing());

            // Wait for any remaining tiles to be processed
            await waitForQueueEmpty();
            // Final check to process any remaining tiles
            if (tileQueue.isNotEmpty) {
              _logger.log('Processing final ${tileQueue.length} tiles...');
              await processTileQueue();
            }
            _logger.log('All tiles processed, closing database...');
            receivePort?.close();
            await db?.close();
            completer.complete();
          }
        }
      });

      // Spawn isolates
      _logger.log('Spawning $totalWorkers isolates...');
      for (final chunk in chunks) {
        final iso = await Isolate.spawn<WorkerInit>(
          downloadWorker,
          WorkerInit(chunk, _urlTemplate, receivePort.sendPort),
        );
        _isolates.add(iso);
      }

      await completer.future;
      if (_canceled) {
        controller.add(const DownloadMapError('Canceled'));
        controller.close();
        return;
      }
      _logger.log(
        'Download completed successfully. Total tiles: $tilesDownloaded',
      );

      // Calculate success rate
      final totalTiles = filteredTiles.length;
      final successRate = (tilesDownloaded / totalTiles * 100).toStringAsFixed(
        1,
      );
      _logger.log('Success rate: $successRate% ($tilesDownloaded/$totalTiles)');

      // Enforce minimum success rate of 70%
      final successFraction = totalTiles == 0
          ? 0.0
          : tilesDownloaded / totalTiles;
      if (successFraction < 0.7) {
        _logger.log(
          'Success rate below threshold (70%). Failing download and deleting MBTiles.',
        );
        try {
          final f = File(mbtilesPath);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (e) {
          _logger.error('Failed to delete MBTiles after low success rate: $e');
        }
        controller.add(
          DownloadMapError(
            'Only ${(successFraction * 100).toStringAsFixed(1)}% of tiles downloaded. Please try again.',
          ),
        );
        controller.close();
        return;
      }

      if (tilesDownloaded < totalTiles) {
        _logger.log(
          'Warning: Some tiles failed to download. The map may have gaps.',
        );
      }

      // Verify the MBTiles file
      _logger.log('Verifying MBTiles file...');
      controller.add(const DownloadMapVerifying());

      final fileSize = await MbtilesVerifier.verifyMbtilesFile(mbtilesPath);

      if (fileSize > 0) {
        _logger.log('File verification successful, yielding success event');
        controller.add(DownloadMapDone(mbtilesPath, fileSize));
      } else {
        _logger.log('File verification failed, yielding error event');
        controller.add(const DownloadMapError('Failed to verify MBTiles file'));
      }

      controller.close();
    } catch (e) {
      _logger.error('Error during download: $e');
      controller.add(DownloadMapError('Download failed: $e'));
      controller.close();
    } finally {
      try {
        await db?.close();
      } catch (_) {}
    }
  }

  List<List<MapTile>> _splitList(List<MapTile> list, int parts) {
    final res = <List<MapTile>>[];
    final chunkSize = (list.length / parts).ceil();
    for (int i = 0; i < list.length; i += chunkSize) {
      res.add(list.sublist(i, math.min(i + chunkSize, list.length)));
    }
    return res;
  }
}
