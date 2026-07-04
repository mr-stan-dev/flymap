import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';

class SkyCameraMediaRepository {
  SkyCameraMediaRepository({required AppDatabase database})
    : _database = database;
  SkyCameraMediaRepository.forTest() : _database = null;

  static const int gridZoom = 6;
  static const int geohashPrecision = 6;

  final AppDatabase? _database;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> watch() => _changes.stream;

  Future<List<SkyCameraMediaItem>> getCapturesByIds(
    Iterable<String> captureIds,
  ) async {
    final ids = captureIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) return const <SkyCameraMediaItem>[];

    final documentsPath = await _documentsPath();
    final captures = <SkyCameraMediaItem>[];
    for (final id in ids) {
      final record = await _databaseOrThrow.skyCameraMediaStore
          .record(id)
          .get(_databaseOrThrow.database);
      if (record == null) continue;
      final capture = await _itemFromRecord(
        Map<String, dynamic>.from(record),
        documentsPath: documentsPath,
      );
      if (capture != null) captures.add(capture);
    }
    return captures;
  }

  Future<List<SkyCameraMediaItem>> getCaptures() async {
    final documentsPath = await _documentsPath();
    final records = await _databaseOrThrow.skyCameraMediaStore.find(
      _databaseOrThrow.database,
      finder: Finder(sortOrders: [SortOrder('capturedAt', false)]),
    );
    return [
      for (final record in records)
        if (await _itemFromRecord(
              Map<String, dynamic>.from(record.value),
              documentsPath: documentsPath,
            )
            case final item?)
          item,
    ];
  }

  Future<List<SkyCameraMediaItem>> getCapturesForFlight(String flightId) async {
    final normalizedFlightId = flightId.trim();
    if (normalizedFlightId.isEmpty) return const <SkyCameraMediaItem>[];
    final documentsPath = await _documentsPath();
    final records = await _databaseOrThrow.skyCameraMediaStore.find(
      _databaseOrThrow.database,
      finder: Finder(
        filter: Filter.equals('flightId', normalizedFlightId),
        sortOrders: [SortOrder('capturedAt', false)],
      ),
    );
    return [
      for (final record in records)
        if (await _itemFromRecord(
              Map<String, dynamic>.from(record.value),
              documentsPath: documentsPath,
            )
            case final item?)
          item,
    ];
  }

  Future<List<SkyCameraMediaItem>> getCapturesInBounds(
    LatLngBounds bounds,
  ) async {
    final candidateKeys = _gridKeysForBounds(bounds);
    if (candidateKeys.isEmpty) return const <SkyCameraMediaItem>[];
    final documentsPath = await _documentsPath();
    final filter = candidateKeys.length == 1
        ? Filter.equals('gridKey', candidateKeys.first)
        : Filter.or(
            candidateKeys
                .map((key) => Filter.equals('gridKey', key))
                .toList(growable: false),
          );
    final records = await _databaseOrThrow.skyCameraMediaStore.find(
      _databaseOrThrow.database,
      finder: Finder(
        filter: filter,
        sortOrders: [SortOrder('capturedAt', false)],
      ),
    );
    final candidates = <SkyCameraMediaItem>[
      for (final record in records)
        if (await _itemFromRecord(
              Map<String, dynamic>.from(record.value),
              documentsPath: documentsPath,
            )
            case final item?)
          item,
    ];
    final filtered =
        candidates
            .where((item) {
              final lat = item.latitude;
              final lon = item.longitude;
              if (lat == null || lon == null) return false;
              return _containsLatLng(bounds, lat, lon);
            })
            .toList(growable: false)
          ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return filtered;
  }

  Future<void> addCapture(SkyCameraMediaItem item) async {
    final normalized = await _normalize(item);
    await _databaseOrThrow.skyCameraMediaStore
        .record(normalized.id)
        .put(_databaseOrThrow.database, normalized.toRecord());
    _changes.add(null);
  }

  Future<void> deleteCaptureIds(Iterable<String> captureIds) async {
    final ids = captureIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) return;

    final documentsPath = await _documentsPath();
    final captures = <SkyCameraMediaItem>[];
    for (final id in ids) {
      final record = await _databaseOrThrow.skyCameraMediaStore
          .record(id)
          .get(_databaseOrThrow.database);
      if (record == null) continue;
      final item = await _itemFromRecord(
        Map<String, dynamic>.from(record),
        documentsPath: documentsPath,
      );
      if (item != null) {
        captures.add(item);
      }
    }

    await _databaseOrThrow.database.transaction((txn) async {
      for (final id in ids) {
        await _databaseOrThrow.skyCameraMediaStore.record(id).delete(txn);
      }
    });

    final paths = <String>{
      for (final capture in captures) ...capture.storedPaths,
    };
    for (final path in paths) {
      final normalizedPath = path.trim();
      if (normalizedPath.isEmpty) continue;
      try {
        final file = File(normalizedPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best-effort cleanup only.
      }
    }

    _changes.add(null);
  }

  AppDatabase get _databaseOrThrow {
    final database = _database;
    if (database == null) {
      throw StateError(
        'SkyCameraMediaRepository test constructor requires overrides.',
      );
    }
    return database;
  }

  Future<SkyCameraMediaItem> _normalize(SkyCameraMediaItem item) async {
    final documentsPath = await _documentsPath();
    final lat = item.latitude ?? item.snapshot.latitude;
    final lon = item.longitude ?? item.snapshot.longitude;
    final hasFiniteCoordinates =
        lat != null && lon != null && lat.isFinite && lon.isFinite;
    final gridKey = hasFiniteCoordinates ? _gridKeyForLatLng(lat, lon) : null;
    final geohash = hasFiniteCoordinates
        ? _encodeGeohash(lat, lon, precision: geohashPrecision)
        : null;
    return item.copyWith(
      sourcePath: _pathForStorage(item.sourcePath, documentsPath),
      renditions: [
        for (final rendition in item.renditions)
          SkyCameraMediaRendition(
            id: rendition.id,
            skinId: rendition.skinId,
            mediaType: rendition.mediaType,
            path: _pathForStorage(rendition.path, documentsPath),
            previewImagePath: _nullablePathForStorage(
              rendition.previewImagePath,
              documentsPath,
            ),
            createdAt: rendition.createdAt,
          ),
      ],
      flightId: item.flightId?.trim(),
      latitude: hasFiniteCoordinates ? lat : null,
      longitude: hasFiniteCoordinates ? lon : null,
      gridKey: gridKey,
      geohash: geohash,
      previewImagePath: _nullablePathForStorage(
        item.previewImagePath,
        documentsPath,
      ),
      outsideTemperatureCelsius:
          item.outsideTemperatureCelsius ??
          item.snapshot.outsideTemperatureCelsius,
    );
  }

  Future<SkyCameraMediaItem?> _itemFromRecord(
    Map<String, dynamic> json, {
    required String documentsPath,
  }) async {
    final item = SkyCameraMediaItem.fromRecord(json);
    if (item == null) return null;
    return item.copyWith(
      sourcePath: _pathForRead(item.sourcePath, documentsPath),
      renditions: [
        for (final rendition in item.renditions)
          SkyCameraMediaRendition(
            id: rendition.id,
            skinId: rendition.skinId,
            mediaType: rendition.mediaType,
            path: _pathForRead(rendition.path, documentsPath),
            previewImagePath: _nullablePathForRead(
              rendition.previewImagePath,
              documentsPath,
            ),
            createdAt: rendition.createdAt,
          ),
      ],
      previewImagePath: _nullablePathForRead(
        item.previewImagePath,
        documentsPath,
      ),
    );
  }

  Future<String> _documentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  String _pathForStorage(String path, String documentsPath) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return trimmed;
    if (p.isAbsolute(trimmed) && p.isWithin(documentsPath, trimmed)) {
      return p.relative(trimmed, from: documentsPath);
    }
    return trimmed;
  }

  String? _nullablePathForStorage(String? path, String documentsPath) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return _pathForStorage(trimmed, documentsPath);
  }

  String _pathForRead(String path, String documentsPath) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!p.isAbsolute(trimmed)) {
      return p.join(documentsPath, trimmed);
    }
    if (trimmed.startsWith('$documentsPath${Platform.pathSeparator}')) {
      return trimmed;
    }
    final documentsMarker =
        '${Platform.pathSeparator}Documents${Platform.pathSeparator}';
    final documentsIndex = trimmed.indexOf(documentsMarker);
    if (documentsIndex >= 0) {
      final relative = trimmed.substring(
        documentsIndex + documentsMarker.length,
      );
      return p.join(documentsPath, relative);
    }
    final skyCameraIndex = trimmed.indexOf(
      '${Platform.pathSeparator}sky_camera${Platform.pathSeparator}',
    );
    if (skyCameraIndex >= 0) {
      final relative = trimmed.substring(skyCameraIndex + 1);
      return p.join(documentsPath, relative);
    }
    return trimmed;
  }

  String? _nullablePathForRead(String? path, String documentsPath) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return _pathForRead(trimmed, documentsPath);
  }

  Set<String> _gridKeysForBounds(LatLngBounds bounds) {
    final ranges = _longitudeRanges(bounds);
    final south = _clampLatitude(bounds.southwest.latitude);
    final north = _clampLatitude(bounds.northeast.latitude);
    final minLat = math.min(south, north);
    final maxLat = math.max(south, north);
    final keys = <String>{};
    for (final range in ranges) {
      final west = _normalizeLongitude(range.$1);
      final east = _normalizeLongitude(range.$2);
      final minTile = _tileCoordinateForLatLng(maxLat, west, gridZoom);
      final maxTile = _tileCoordinateForLatLng(minLat, east, gridZoom);
      final yStart = math.min(minTile.$2, maxTile.$2);
      final yEnd = math.max(minTile.$2, maxTile.$2);
      final xStart = math.min(minTile.$1, maxTile.$1);
      final xEnd = math.max(minTile.$1, maxTile.$1);
      for (var x = xStart; x <= xEnd; x++) {
        for (var y = yStart; y <= yEnd; y++) {
          keys.add('z$gridZoom/$x/$y');
        }
      }
    }
    return keys;
  }

  bool _containsLatLng(LatLngBounds bounds, double lat, double lon) {
    final south = math.min(
      bounds.southwest.latitude,
      bounds.northeast.latitude,
    );
    final north = math.max(
      bounds.southwest.latitude,
      bounds.northeast.latitude,
    );
    if (lat < south || lat > north) return false;
    final ranges = _longitudeRanges(bounds);
    final normalizedLon = _normalizeLongitude(lon);
    for (final range in ranges) {
      final west = _normalizeLongitude(range.$1);
      final east = _normalizeLongitude(range.$2);
      if (normalizedLon >= west && normalizedLon <= east) {
        return true;
      }
    }
    return false;
  }

  List<(double, double)> _longitudeRanges(LatLngBounds bounds) {
    final west = _normalizeLongitude(bounds.southwest.longitude);
    final east = _normalizeLongitude(bounds.northeast.longitude);
    if (west <= east) return <(double, double)>[(west, east)];
    return <(double, double)>[(west, 180.0), (-180.0, east)];
  }

  String _gridKeyForLatLng(double lat, double lon) {
    final tile = _tileCoordinateForLatLng(lat, lon, gridZoom);
    return 'z$gridZoom/${tile.$1}/${tile.$2}';
  }

  (int, int) _tileCoordinateForLatLng(double lat, double lon, int zoom) {
    final normalizedLat = _clampLatitude(lat);
    final normalizedLon = _normalizeLongitude(lon);
    final scale = 1 << zoom;
    final x = ((normalizedLon + 180.0) / 360.0 * scale).floor().clamp(
      0,
      scale - 1,
    );
    final latRad = normalizedLat * math.pi / 180.0;
    final mercator = math.log(math.tan(math.pi / 4.0 + latRad / 2.0));
    final y = ((1.0 - mercator / math.pi) / 2.0 * scale).floor().clamp(
      0,
      scale - 1,
    );
    return (x, y);
  }

  double _clampLatitude(double lat) {
    return lat.clamp(-85.05112878, 85.05112878);
  }

  double _normalizeLongitude(double lon) {
    var normalized = lon;
    while (normalized < -180.0) {
      normalized += 360.0;
    }
    while (normalized > 180.0) {
      normalized -= 360.0;
    }
    return normalized;
  }

  String _encodeGeohash(
    double latitude,
    double longitude, {
    required int precision,
  }) {
    const alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';
    var minLat = -90.0;
    var maxLat = 90.0;
    var minLon = -180.0;
    var maxLon = 180.0;
    final hash = StringBuffer();
    var isLongitudeBit = true;
    var bit = 0;
    var ch = 0;

    while (hash.length < precision) {
      if (isLongitudeBit) {
        final mid = (minLon + maxLon) / 2.0;
        if (longitude >= mid) {
          ch |= 1 << (4 - bit);
          minLon = mid;
        } else {
          maxLon = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2.0;
        if (latitude >= mid) {
          ch |= 1 << (4 - bit);
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      isLongitudeBit = !isLongitudeBit;
      if (bit < 4) {
        bit++;
        continue;
      }

      hash.write(alphabet[ch]);
      bit = 0;
      ch = 0;
    }

    return hash.toString();
  }
}
