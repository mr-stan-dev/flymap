import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/route_poi.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

typedef AssetLoader = Future<ByteData> Function(String assetPath);
typedef DocumentsDirectoryProvider = Future<Directory> Function();
typedef OpenReadOnlyDatabase = Future<Database> Function(String path);

class PlacesWikiLocalDataSource {
  PlacesWikiLocalDataSource({
    AssetLoader? assetLoader,
    DocumentsDirectoryProvider? documentsDirectoryProvider,
    OpenReadOnlyDatabase? openReadOnlyDatabase,
  }) : _assetLoader = assetLoader ?? rootBundle.load,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _openReadOnlyDatabase =
           openReadOnlyDatabase ??
           ((path) => openDatabase(path, readOnly: true, singleInstance: true));

  static const String _assetPath = 'assets/data/places_wiki.db';
  static const String _dbFileName = 'places_wiki.db';
  static const String _versionFileName = 'places_wiki.version';
  // Bump this when shipping a new assets/data/places_wiki.db snapshot.
  static const int _placesWikiDbVersion = 1;

  final Logger _logger = const Logger('PlacesWikiLocalDataSource');
  final AssetLoader _assetLoader;
  final DocumentsDirectoryProvider _documentsDirectoryProvider;
  final OpenReadOnlyDatabase _openReadOnlyDatabase;

  Database? _db;
  bool? _rtreeAvailable;
  bool? _rtreeCompileOptionEnabled;

  Future<void> initialize() async {
    if (_db != null) {
      _logger.log('places_wiki.db already initialized');
      return;
    }

    final docsDir = await _documentsDirectoryProvider();
    final dbPath = p.join(docsDir.path, _dbFileName);
    final versionPath = p.join(docsDir.path, _versionFileName);
    final dbFile = File(dbPath);
    final versionFile = File(versionPath);

    final exists = await dbFile.exists();
    final currentVersion = await _readDbVersion(versionFile);
    final shouldCopy = !exists || currentVersion != _placesWikiDbVersion;

    if (shouldCopy) {
      _logger.log(
        'Refreshing places_wiki.db asset (exists=$exists currentVersion=$currentVersion targetVersion=$_placesWikiDbVersion)',
      );
      await _copyDbAsset(dbFile);
      await _writeDbVersion(versionFile, _placesWikiDbVersion);
    } else {
      _logger.log('places_wiki.db is up to date (version=$currentVersion)');
    }
    _logger.log('Using places_wiki.db at $dbPath');

    _db = await _openReadOnlyDatabase(dbPath);
    _logger.log('places_wiki.db opened (read-only)');
    await _logSqliteCapabilities(_db!);
  }

  Future<List<RoutePoi>> queryByBounds({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required int limit,
  }) async {
    final stopwatch = Stopwatch()..start();
    await initialize();
    final db = _db;
    if (db == null) return const [];

    final boundedLimit = limit <= 0 ? null : limit;
    _logger.log(
      'queryByBounds minLat=$minLat maxLat=$maxLat minLon=$minLon maxLon=$maxLon '
      'limit=${boundedLimit ?? 'ALL'}',
    );
    final queryResult = await _queryRows(
      db: db,
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      limit: boundedLimit,
    );
    final pois = queryResult.rows.map(_toRoutePoi).toList(growable: false);
    final sample = pois
        .take(3)
        .map((e) => '${e.name}/${e.type.rawValue}')
        .join(', ');
    stopwatch.stop();
    _logger.log(
      'queryByBounds fetched=${pois.length} strategy=${queryResult.strategy} '
      'elapsedMs=${stopwatch.elapsedMilliseconds}'
      '${sample.isEmpty ? '' : ' sample=[$sample]'}',
    );
    return pois;
  }

  Future<_RowsQueryResult> _queryRows({
    required Database db,
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required int? limit,
  }) async {
    if (_rtreeAvailable != false) {
      try {
        final rows = limit == null
            ? await db.rawQuery(
                '''
          SELECT p.qid, p.name, p.lat, p.lon, p.sitelinks, p.place_type
          FROM places p
          JOIN places_rtree r ON p.rowid = r.id
          WHERE r.minLon <= ? AND r.maxLon >= ?
            AND r.minLat <= ? AND r.maxLat >= ?
          ORDER BY p.sitelinks DESC, p.qid ASC
          ''',
                [maxLon, minLon, maxLat, minLat],
              )
            : await db.rawQuery(
                '''
          SELECT p.qid, p.name, p.lat, p.lon, p.sitelinks, p.place_type
          FROM places p
          JOIN places_rtree r ON p.rowid = r.id
          WHERE r.minLon <= ? AND r.maxLon >= ?
            AND r.minLat <= ? AND r.maxLat >= ?
          ORDER BY p.sitelinks DESC, p.qid ASC
          LIMIT ?
          ''',
                [maxLon, minLon, maxLat, minLat, limit],
              );
        _rtreeAvailable = true;
        return _RowsQueryResult(rows: rows, strategy: 'rtree');
      } on DatabaseException catch (e) {
        final message = e.toString().toLowerCase();
        if (message.contains('no such module: rtree')) {
          _rtreeAvailable = false;
          _logger.log(
            'RTREE unavailable in SQLite build; falling back to plain lat/lon query '
            '(compileOption=$_rtreeCompileOptionEnabled)',
          );
        } else {
          rethrow;
        }
      }
    }

    final fallbackRows = limit == null
        ? await db.rawQuery(
            '''
      SELECT p.qid, p.name, p.lat, p.lon, p.sitelinks, p.place_type
      FROM places p
      WHERE p.lon <= ? AND p.lon >= ?
        AND p.lat <= ? AND p.lat >= ?
      ORDER BY p.sitelinks DESC, p.qid ASC
      ''',
            [maxLon, minLon, maxLat, minLat],
          )
        : await db.rawQuery(
            '''
      SELECT p.qid, p.name, p.lat, p.lon, p.sitelinks, p.place_type
      FROM places p
      WHERE p.lon <= ? AND p.lon >= ?
        AND p.lat <= ? AND p.lat >= ?
      ORDER BY p.sitelinks DESC, p.qid ASC
      LIMIT ?
      ''',
            [maxLon, minLon, maxLat, minLat, limit],
          );
    return _RowsQueryResult(rows: fallbackRows, strategy: 'bbox_plain');
  }

  Future<void> _logSqliteCapabilities(Database db) async {
    try {
      final versionRows = await db.rawQuery(
        'SELECT sqlite_version() AS sqlite_version',
      );
      final sqliteVersion = versionRows.firstOrNull?['sqlite_version'];
      final compileOptionRows = await db.rawQuery('PRAGMA compile_options');
      final compileOptions = compileOptionRows
          .map((row) => (row.values.firstOrNull ?? '').toString())
          .where((row) => row.isNotEmpty)
          .toList(growable: false);
      _rtreeCompileOptionEnabled = compileOptions.any(
        (option) => option.toUpperCase().contains('ENABLE_RTREE'),
      );
      _logger.log(
        'SQLite capabilities version=$sqliteVersion compileOptions=${compileOptions.length} '
        'enableRtree=$_rtreeCompileOptionEnabled',
      );
    } catch (e) {
      _logger.error('Failed to inspect SQLite compile options: $e');
    }
  }

  Future<void> _copyDbAsset(File dbFile) async {
    final data = await _assetLoader(_assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await dbFile.writeAsBytes(bytes, flush: true);
  }

  Future<int?> _readDbVersion(File versionFile) async {
    if (!await versionFile.exists()) return null;
    try {
      final raw = await versionFile.readAsString();
      return int.tryParse(raw.trim());
    } catch (e) {
      _logger.error('Failed to read places_wiki version file: $e');
      return null;
    }
  }

  Future<void> _writeDbVersion(File versionFile, int version) async {
    try {
      await versionFile.writeAsString('$version', flush: true);
    } catch (e) {
      _logger.error('Failed to write places_wiki version file: $e');
    }
  }

  RoutePoi _toRoutePoi(Map<String, Object?> row) {
    final qid = (row['qid'] ?? '').toString();
    final name = (row['name'] ?? '').toString();
    final lat = (row['lat'] as num?)?.toDouble() ?? 0.0;
    final lon = (row['lon'] as num?)?.toDouble() ?? 0.0;
    final sitelinks = (row['sitelinks'] as num?)?.toInt() ?? 0;
    final placeTypeRaw = (row['place_type'] ?? '').toString();
    return RoutePoi(
      qid: qid,
      name: name,
      latLon: LatLng(lat, lon),
      type: FlightPoiType.fromRaw(placeTypeRaw),
      sitelinks: sitelinks,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

class _RowsQueryResult {
  const _RowsQueryResult({required this.rows, required this.strategy});

  final List<Map<String, Object?>> rows;
  final String strategy;
}
