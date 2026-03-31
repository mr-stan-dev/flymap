import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flymap/entity/flight.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/map_download_config.dart';
import 'package:sembast/sembast_io.dart';

import 'app_database.dart';
import 'mappers/flight_article_db_mapper.dart';
import 'mappers/flight_db_mapper.dart';
import 'mappers/flight_info_db_mapper.dart';
import 'mappers/flight_map_mapper.dart';

class FlightsDBService {
  final AppDatabase _database;
  final FlightDbMapper _flightMapper;
  final _logger = Logger('FlightsLocalDBService');

  FlightsDBService({
    required AppDatabase database,
    required FlightDbMapper flightMapper,
  }) : _database = database,
       _flightMapper = flightMapper;

  Future<String> insertFlight(Flight flight) async {
    final key = flight.id;
    _logger.log('Saving new flight: ${flight.id}');
    final map = _flightMapper.toDb(flight);
    await _database.flightsStore.record(key).put(_database.database, map);
    return key;
  }

  Future<Flight?> getFlightById(String flightId) async {
    final map = await _database.flightsStore
        .record(flightId)
        .get(_database.database);
    if (map == null) return null;
    return _flightMapper.fromDb(map);
  }

  Future<List<Flight>> getAllFlights() async {
    final records = await _database.flightsStore.find(_database.database);
    return records.map((record) => _flightMapper.fromDb(record.value)).toList();
  }

  Future<List<Flight>> getRecentFlights({int limit = 10}) async {
    final records = await _database.flightsStore.find(
      _database.database,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)], limit: limit),
    );
    return records.map((record) => _flightMapper.fromDb(record.value)).toList();
  }

  Future<bool> deleteFlight(String flightId) async {
    final existing = await _database.flightsStore
        .record(flightId)
        .get(_database.database);
    if (existing == null) return false;

    await _deleteMapFiles(existing);

    await _database.flightsStore.record(flightId).delete(_database.database);
    return true;
  }

  Future<void> _deleteMapFiles(dynamic flight) async {
    // Remove associated map files from disk if present
    try {
      final map = (flight as Map);
      final dynamic mapsRaw = map[FlightDBKeys.flightMaps];
      _logger.log('Deleted map list: ${mapsRaw is List}');
      if (mapsRaw is List) {
        final appDir = await getApplicationCacheDirectory();
        for (final m in mapsRaw.whereType<Map>()) {
          final storedPath = (m[FlightMapDBKeys.filePath])?.toString();
          if (storedPath != null && storedPath.isNotEmpty) {
            // DB stores only the filename; construct full path
            final fileName = p.basename(storedPath);
            final filePath = p.join(
              appDir.path,
              MapDownloadConfig.mbtilesDirectoryName,
              fileName,
            );
            _logger.log('Deleting map file: $filePath');
            final f = File(filePath);
            if (f.existsSync()) {
              try {
                f.deleteSync();
                _logger.log('Deleted map file: $filePath');
              } catch (e) {
                _logger.error('Failed to delete $filePath: $e');
              }
            }
            _deleteSidecars(filePath);
          }
        }
      }

      final dynamic infoRaw = map[FlightDBKeys.flightInfo];
      if (infoRaw is Map) {
        final dynamic articlesRaw = infoRaw[FlightInfoDBKeys.articles];
        if (articlesRaw is List) {
          final appDocDir = await getApplicationDocumentsDirectory();
          final articleRootPath = p.join(appDocDir.path, 'article_media');
          for (final article in articlesRaw.whereType<Map>()) {
            final pathsToDelete = <String>{};

            final leadPath = article[FlightArticleDBKeys.leadImageRelativePath]
                ?.toString();
            if (leadPath != null && leadPath.isNotEmpty) {
              pathsToDelete.add(leadPath);
            }

            final inlinePathsRaw =
                article[FlightArticleDBKeys.inlineImageRelativePaths];
            if (inlinePathsRaw is List) {
              for (final path in inlinePathsRaw.whereType<String>()) {
                if (path.trim().isNotEmpty) {
                  pathsToDelete.add(path);
                }
              }
            }

            for (final relativePath in pathsToDelete) {
              final imagePath = p.join(appDocDir.path, relativePath);
              final imageFile = File(imagePath);
              if (!imageFile.existsSync()) continue;
              try {
                imageFile.deleteSync();
                _logger.log('Deleted article image: $imagePath');
                _deleteEmptyArticleDirs(
                  startDir: imageFile.parent,
                  articleRootPath: articleRootPath,
                );
              } catch (e) {
                _logger.error('Failed to delete article image $imagePath: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.error('Error deleting map files for flight $flight: $e');
    }
  }

  void _deleteSidecars(String mainPath) {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('$mainPath$suffix');
      if (sidecar.existsSync()) {
        try {
          sidecar.deleteSync();
          _logger.log('Deleted sidecar file: ${sidecar.path}');
        } catch (e) {
          _logger.error('Failed to delete sidecar ${sidecar.path}: $e');
        }
      }
    }
  }

  void _deleteEmptyArticleDirs({
    required Directory startDir,
    required String articleRootPath,
  }) {
    var current = startDir;
    while (true) {
      final currentPath = current.path;
      if (currentPath == articleRootPath ||
          !p.isWithin(articleRootPath, currentPath)) {
        break;
      }

      final children = current.listSync();
      if (children.isNotEmpty) break;

      try {
        current.deleteSync();
      } catch (_) {
        break;
      }

      current = current.parent;
    }
  }
}
