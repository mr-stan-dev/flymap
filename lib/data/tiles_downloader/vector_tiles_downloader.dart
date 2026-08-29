import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flymap/data/tiles_downloader/ios_backup_exclusion.dart';
import 'package:flymap/data/tiles_downloader/mbtiles_verifier.dart';
import 'package:flymap/data/tiles_downloader/sea_tiles_filter.dart';
import 'package:flymap/data/tiles_downloader/tile_utils.dart';
import 'package:flymap/data/tiles_downloader/vector_tiles_db.dart';
import 'package:flymap/data/tiles_downloader/vector_tiles_worker.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/map_download_config.dart';
import 'package:flymap/domain/usecase/download_map_use_case.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class VectorTilesDownloader {
  final List<List<LatLng>> polygons;
  final int minZoom;
  final int maxZoom;
  final int isolatesCount;
  final _logger = Logger('VectorTilesDownloader');
  final IosBackupExclusion _iosBackupExclusion;

  VectorTilesDownloader({
    List<LatLng>? polygon,
    List<List<LatLng>>? polygons,
    required this.minZoom,
    required this.maxZoom,
    this.isolatesCount = MapDownloadConfig.defaultWorkerCount,
    IosBackupExclusion? iosBackupExclusion,
  }) : polygons = polygons ?? (polygon == null ? const [] : [polygon]),
       _iosBackupExclusion = iosBackupExclusion ?? IosBackupExclusion();

  final List<Isolate> _isolates = [];
  ReceivePort? _receivePort;
  StreamSubscription<dynamic>? _receiveSubscription;
  Completer<void>? _cancelCompleter;
  bool _canceled = false;

  /// Cancels an in-flight download and unblocks all waiting async paths.
  /// Safe to call multiple times.
  void cancel() {
    if (_canceled) return;
    _canceled = true;
    for (final iso in _isolates) {
      iso.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _receiveSubscription?.cancel();
    _receiveSubscription = null;
    _receivePort?.close();
    _receivePort = null;
    final cancelCompleter = _cancelCompleter;
    if (cancelCompleter != null && !cancelCompleter.isCompleted) {
      cancelCompleter.complete();
    }
  }

  /// Starts a new download stream for the given output file name.
  Stream<DownloadMapEvent> download(String fileName) {
    final controller = StreamController<DownloadMapEvent>();
    _performDownload(fileName, controller);
    return controller.stream;
  }

  /// Main orchestration flow:
  /// 1) create MBTiles DB, 2) compute/filter tiles, 3) download with isolates,
  /// 4) write tiles with backpressure, 5) verify and emit final event.
  Future<void> _performDownload(
    String fileName,
    StreamController<DownloadMapEvent> controller,
  ) async {
    Database? db;
    String? mbtilesPath;
    String? workPath;
    var keepArtifacts = false;
    _cancelCompleter = Completer<void>();
    try {
      if (_canceled) {
        _safeAdd(controller, const DownloadMapError('Canceled'));
        await _safeClose(controller);
        return;
      }

      final validPolygons = polygons
          .where((polygon) => polygon.length >= 3)
          .toList(growable: false);
      final pointsCount = validPolygons.fold<int>(
        0,
        (sum, polygon) => sum + polygon.length,
      );
      _logger.log(
        'Starting download for ${validPolygons.length} polygon(s) with $pointsCount total points, zoom $minZoom-$maxZoom',
      );

      // Initializing
      controller.add(const DownloadMapInitializing());

      // Get proper directory path
      // Offline maps must survive Android cache eviction. Unlike glyphs and
      // other recreatable assets, an MBTiles file cannot be recovered while
      // the user is offline, so keep new downloads in durable app storage.
      final appDir = await getApplicationSupportDirectory();
      final targetDirPath = p.join(
        appDir.path,
        MapDownloadConfig.mbtilesDirectoryName,
      );

      mbtilesPath = p.join(targetDirPath, '$fileName.mbtiles');
      // All writes go to a .part work file; the final path is only touched
      // by the atomic promotion after verification. A failed or cancelled
      // re-download of a route can therefore never destroy an existing good
      // map for that route (which another flight may still depend on).
      workPath = '$mbtilesPath.part';
      _logger.log('MBTiles file: $mbtilesPath (work file: $workPath)');

      // Ensure target directory exists
      final targetDirectory = Directory(targetDirPath);
      if (!await targetDirectory.exists()) {
        _logger.log('Creating target directory: $targetDirPath');
        await targetDirectory.create(recursive: true);
      }

      // Clear any stale work file left by an earlier kill/crash.
      await _deleteMbtilesArtifacts(workPath);

      // Create database using sqflite
      final dbHelper = VectorTilesDb();
      db = await openDatabase(
        workPath,
        version: 1,
        onCreate: dbHelper.createMbtilesSchema,
      );

      if (_canceled) {
        await db.close();
        _safeAdd(controller, const DownloadMapError('Canceled'));
        await _safeClose(controller);
        return;
      }

      // Compute all tiles
      final allTilesByKey = <String, MapTile>{};
      for (int z = minZoom; z <= maxZoom; z++) {
        for (final polygon in validPolygons) {
          for (final tile in TileUtils.tilesForPolygon(polygon, z)) {
            allTilesByKey['${tile.z}/${tile.x}/${tile.y}'] = tile;
          }
        }
      }
      final allTiles = allTilesByKey.values.toList(growable: false);
      final validTiles = allTiles
          .where(TileUtils.isValidTile)
          .toList(growable: false);
      final invalidTilesSkipped = allTiles.length - validTiles.length;
      if (invalidTilesSkipped > 0) {
        _logger.log(
          'Skipped $invalidTilesSkipped invalid tile coordinates before sea filtering',
        );
      }

      // Filter out sea tiles from configured sea-filter zoom and above.
      final seaFilter = SeaTilesFilter(
        minZoomToFilter: MapDownloadConfig.seaFilterMinZoom,
      );
      final filteredTiles = await seaFilter.filterTiles(validTiles);
      final skipped = validTiles.length - filteredTiles.length;
      final skippedByZoom = _buildSkippedByZoom(
        allTiles: validTiles,
        filteredTiles: filteredTiles,
      );
      _logger.log(
        'Computed ${validTiles.length} valid tiles; skipped $skipped sea tiles; downloading ${filteredTiles.length} tiles',
      );
      if (skippedByZoom.isNotEmpty) {
        final details = skippedByZoom.entries
            .map((entry) => 'z${entry.key}:${entry.value}')
            .join(', ');
        _logger.log('Sea filter skipped by zoom: $details');
      } else {
        _logger.log(
          'Sea filter skipped by zoom: none (every selected tile intersects land).',
        );
      }

      // Computing tiles event
      controller.add(DownloadMapComputingTiles(filteredTiles.length));

      if (filteredTiles.isEmpty) {
        _logger.log('No tiles selected for download.');
        _safeAdd(
          controller,
          const DownloadMapError('No tiles found for the selected area.'),
        );
        await _safeClose(controller);
        return;
      }

      // Split tiles into chunks
      final chunks = _splitList(filteredTiles, math.max(1, isolatesCount));
      _logger.log(
        'Split into ${chunks.length} chunks with $isolatesCount isolates',
      );

      // Starting workers event
      controller.add(DownloadMapStartingWorkers(chunks.length));

      // Receive port for worker communication.
      _receivePort = ReceivePort();
      final receivePort = _receivePort!;
      final totalWorkers = chunks.length;
      int completed = 0;
      int tilesDownloaded = 0;
      int bytesDownloaded = 0;
      final completer = Completer<void>();
      final tileQueue = Queue<TileData>();
      const maxQueueSize = 600;
      const resumeQueueSize = 250;
      bool isProcessingQueue = false;

      // Processes the in-memory tile queue on a single async lane.
      // We serialize DB inserts to avoid sqlite write contention.
      Future<void> processTileQueue() async {
        if (isProcessingQueue) return;
        isProcessingQueue = true;

        while (tileQueue.isNotEmpty) {
          if (_canceled) {
            isProcessingQueue = false;
            return;
          }
          final tile = tileQueue.removeFirst();
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
            bytesDownloaded += tile.bytes.length;

            // Log progress updates every 10 tiles
            if (tilesDownloaded % 10 == 0) {
              final progress = tilesDownloaded / filteredTiles.length;
              controller.add(
                DownloadMapProgress(progress, downloadedBytes: bytesDownloaded),
              );
              _logger.log(
                'Downloaded $tilesDownloaded/${filteredTiles.length} tiles (${(tilesDownloaded / filteredTiles.length * 100).toStringAsFixed(1)}%)',
              );
            }
          } catch (e) {
            _logger.error('Error inserting tile: $e');
          }

          if (_receiveSubscription?.isPaused == true &&
              tileQueue.length <= resumeQueueSize) {
            _receiveSubscription?.resume();
          }
        }
        isProcessingQueue = false;
      }

      // Waits until all queued tile writes are finished.
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

      // Listen for worker output. Backpressure is applied by pausing this
      // subscription when queue grows too much, then resuming after drain.
      _receiveSubscription = receivePort.listen((message) async {
        if (_canceled) return;
        if (message is TileData) {
          // Add to queue and process
          tileQueue.addLast(message);
          if (_receiveSubscription?.isPaused == false &&
              tileQueue.length >= maxQueueSize) {
            _receiveSubscription?.pause();
          }
          unawaited(processTileQueue());
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
            _receiveSubscription?.cancel();
            _receiveSubscription = null;
            _receivePort?.close();
            _receivePort = null;
            await db?.close();
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }
      });

      // Spawn one worker isolate per chunk.
      _logger.log('Spawning $totalWorkers isolates...');
      try {
        for (final chunk in chunks) {
          final iso = await Isolate.spawn<WorkerInit>(
            downloadWorker,
            WorkerInit(
              chunk,
              primaryTemplate: MapDownloadConfig.flymapTiles,
              fallbackTemplate: MapDownloadConfig.ofmTiles,
              sendPort: receivePort.sendPort,
            ),
          );
          _isolates.add(iso);
        }
      } catch (e) {
        _logger.error('Failed to spawn worker isolate: $e');
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }

      await Future.any<void>([completer.future, _cancelCompleter!.future]);
      if (_canceled) {
        _safeAdd(controller, const DownloadMapError('Canceled'));
        await _safeClose(controller);
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
          final f = File(workPath);
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

      final verification = await MbtilesVerifier.verifyMbtilesFile(workPath);

      if (verification.isValid) {
        // Close before renaming so the data is checkpointed into the main
        // file and no handle points at the old path.
        await db.close();
        db = null;
        await _promoteWorkFile(workPath, mbtilesPath);
        try {
          await _iosBackupExclusion.exclude(mbtilesPath);
        } catch (e) {
          // Backup metadata is independent of map integrity. Keep the verified
          // offline map usable even if iOS cannot persist the attribute.
          _logger.error('Failed to exclude MBTiles from iOS backup: $e');
        }
        _logger.log('File verification successful, yielding success event');
        keepArtifacts = true;
        controller.add(DownloadMapDone(mbtilesPath, verification.fileSize));
      } else {
        final verifierError =
            verification.errorMessage ?? 'unknown verification error';
        _logger.log('File verification failed, yielding error event');
        controller.add(
          DownloadMapError('Failed to verify MBTiles file: $verifierError'),
        );
      }

      await _safeClose(controller);
    } catch (e) {
      _logger.error('Error during download: $e');
      if (_canceled) {
        _safeAdd(controller, const DownloadMapError('Canceled'));
      } else {
        _safeAdd(controller, DownloadMapError('Download failed: $e'));
      }
      await _safeClose(controller);
    } finally {
      _receiveSubscription?.cancel();
      _receiveSubscription = null;
      _receivePort?.close();
      _receivePort = null;
      for (final iso in _isolates) {
        iso.kill(priority: Isolate.immediate);
      }
      _isolates.clear();
      _cancelCompleter = null;
      try {
        await db?.close();
      } catch (_) {}
      // Only ever clean up the work file: the final path holds the previous
      // good map (if any) and must survive failed/cancelled re-downloads.
      if (!keepArtifacts && workPath != null) {
        await _deleteMbtilesArtifacts(workPath);
      }
    }
  }

  /// Replaces the final MBTiles with the verified work file. The previous
  /// good file stays intact until this moment, so interruptions before the
  /// rename leave it untouched.
  Future<void> _promoteWorkFile(String workPath, String finalPath) async {
    // Sqlite data is checkpointed into the main file on close; leftover
    // sidecars from either path are stale and must not shadow the new db.
    await _resetMbtilesSidecars(workPath);
    await _resetMbtilesSidecars(finalPath);
    final finalFile = File(finalPath);
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await File(workPath).rename(finalPath);
    _logger.log('Promoted work file to $finalPath');
  }

  /// Splits the input into near-even chunks for worker fan-out.
  List<List<MapTile>> _splitList(List<MapTile> list, int parts) {
    if (list.isEmpty) return const [];
    final safeParts = math.max(1, parts);
    final res = <List<MapTile>>[];
    final chunkSize = (list.length / safeParts).ceil();
    for (int i = 0; i < list.length; i += chunkSize) {
      res.add(list.sublist(i, math.min(i + chunkSize, list.length)));
    }
    return res;
  }

  /// Adds an event only if the controller is still open.
  void _safeAdd(
    StreamController<DownloadMapEvent> controller,
    DownloadMapEvent event,
  ) {
    if (controller.isClosed) return;
    try {
      controller.add(event);
    } catch (_) {}
  }

  /// Closes the controller defensively (ignores close races).
  Future<void> _safeClose(StreamController<DownloadMapEvent> controller) async {
    if (controller.isClosed) return;
    try {
      await controller.close();
    } catch (_) {}
  }

  Future<void> _resetMbtilesSidecars(String mbtilesPath) async {
    final artifactPaths = <String>[
      '$mbtilesPath-wal',
      '$mbtilesPath-shm',
      '$mbtilesPath-journal',
    ];
    for (final path in artifactPaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      _logger.log('Deleting stale MBTiles artifact: $path');
      await file.delete();
    }
  }

  Future<void> _deleteMbtilesArtifacts(String mbtilesPath) async {
    final artifactPaths = <String>[
      mbtilesPath,
      '$mbtilesPath-wal',
      '$mbtilesPath-shm',
      '$mbtilesPath-journal',
    ];
    for (final path in artifactPaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      try {
        _logger.log('Deleting unfinished MBTiles artifact: $path');
        await file.delete();
      } catch (e) {
        _logger.error('Failed to delete unfinished MBTiles artifact $path: $e');
      }
    }
  }

  Map<int, int> _buildSkippedByZoom({
    required List<MapTile> allTiles,
    required List<MapTile> filteredTiles,
  }) {
    final allByZoom = <int, int>{};
    final filteredByZoom = <int, int>{};

    for (final tile in allTiles) {
      allByZoom[tile.z] = (allByZoom[tile.z] ?? 0) + 1;
    }
    for (final tile in filteredTiles) {
      filteredByZoom[tile.z] = (filteredByZoom[tile.z] ?? 0) + 1;
    }

    final skippedByZoom = <int, int>{};
    for (final entry in allByZoom.entries) {
      final skipped = entry.value - (filteredByZoom[entry.key] ?? 0);
      if (skipped > 0) {
        skippedByZoom[entry.key] = skipped;
      }
    }
    return skippedByZoom;
  }
}
