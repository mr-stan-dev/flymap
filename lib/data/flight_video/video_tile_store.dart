import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flymap/data/api/mapbox_raster_tile_api.dart';
import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/flight_video/rendering/tile_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Result of a tile prefetch pass.
class TilePrefetchResult {
  const TilePrefetchResult({required this.total, required this.failed});

  final int total;
  final int failed;

  /// A few missing tiles are hidden by parent-tile fallback at draw time;
  /// beyond that the video would visibly degrade.
  bool get isUsable => total == 0 || failed / total < 0.1;
}

/// Downloads, disk-caches and decodes the raster tiles of one flight video.
///
/// One instance per video generation: [prefetch] fills the disk cache
/// up-front (so the render loop never touches the network), [ensureDecoded]
/// keeps the tiles of the current frame in a bounded decoded-image LRU, and
/// [imageFor] is the synchronous paint-time lookup.
class VideoTileStore implements TileResolver {
  VideoTileStore({
    required MapboxRasterTileApi api,
    required FlightVideoMapStyle style,
    Future<Directory> Function()? cacheDirectoryProvider,
    int decodedCacheCapacity = defaultDecodedCacheCapacity,
  }) : _api = api,
       _style = style,
       _cacheDirectoryProvider =
           cacheDirectoryProvider ?? getApplicationCacheDirectory,
       _decodedCacheCapacity = decodedCacheCapacity;

  /// Must comfortably exceed the per-frame tile budget
  /// (`kMaxTilesPerFrame` = 64) plus parents and preview look-ahead, or
  /// frames evict their own tiles mid-decode (grey/black tiles + decode
  /// churn on every frame). 160 decoded 512px tiles ~= 160 MB transient
  /// peak; the single-tile-level scheme keeps real usage well below this.
  static const int defaultDecodedCacheCapacity = 160;
  static const String cacheSubdirectory = 'flight_video_tiles';
  static const Duration cacheTtl = Duration(days: 30);
  static const int maxCacheBytes = 150 * 1024 * 1024;

  final MapboxRasterTileApi _api;
  final FlightVideoMapStyle _style;
  final Future<Directory> Function() _cacheDirectoryProvider;
  final int _decodedCacheCapacity;
  final Logger _logger = const Logger('VideoTileStore');

  final LinkedHashMap<TileCoord, ui.Image> _decoded = LinkedHashMap();
  Directory? _cacheDir;
  bool _disposed = false;

  /// Downloads every tile in [tiles] that is not already disk-cached.
  ///
  /// A long route can need hundreds of tiles (up to [kMaxManifestTiles]); the
  /// wall time is dominated by per-tile network latency, so we fan out wide —
  /// the Mapbox Static Tiles API handles this concurrency comfortably.
  Future<TilePrefetchResult> prefetch(
    Set<TileCoord> tiles, {
    void Function(int done, int total)? onProgress,
    int concurrency = 24,
    FlightVideoCancelToken? cancel,
  }) async {
    final queue = List<TileCoord>.from(tiles);
    final total = queue.length;
    var done = 0;
    var failed = 0;
    var cached = 0;
    var downloaded = 0;
    final sw = Stopwatch()..start();

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        if (cancel?.isCancelled ?? false) return;
        final coord = queue.removeLast();
        final outcome = await _ensureOnDisk(coord);
        switch (outcome) {
          case _TileDiskOutcome.cached:
            cached++;
          case _TileDiskOutcome.downloaded:
            downloaded++;
          case _TileDiskOutcome.failed:
            failed++;
        }
        done++;
        onProgress?.call(done, total);
      }
    }

    _logger.log('prefetch: start $total tiles, concurrency=$concurrency');
    await Future.wait([
      for (var i = 0; i < concurrency; i++) worker(),
    ]);
    _logger.log(
      'prefetch: done in ${sw.elapsedMilliseconds}ms — '
      '$cached cached, $downloaded downloaded, $failed failed',
    );
    if (!(cancel?.isCancelled ?? false)) {
      final trimSw = Stopwatch()..start();
      await _trimDiskCache();
      _logger.log('prefetch: trimDiskCache took ${trimSw.elapsedMilliseconds}ms');
    }
    return TilePrefetchResult(total: total, failed: failed);
  }

  /// Decodes any of [tiles] not yet in the LRU. Call per frame before paint.
  /// Missing tiles decode 4 at a time (disk read + image decode overlap).
  Future<void> ensureDecoded(Iterable<TileCoord> tiles) async {
    const concurrency = 4;
    final missing = <TileCoord>[];
    for (final coord in tiles) {
      final image = _decoded.remove(coord);
      if (image != null) {
        // Refresh LRU position.
        _decoded[coord] = image;
      } else {
        missing.add(coord);
      }
    }

    for (var i = 0; i < missing.length; i += concurrency) {
      if (_disposed) return;
      final chunk = missing.sublist(
        i,
        (i + concurrency).clamp(0, missing.length),
      );
      final images = await Future.wait(chunk.map(_decodeFromDisk));
      for (var j = 0; j < chunk.length; j++) {
        final image = images[j];
        if (image == null) continue;
        if (_disposed) {
          image.dispose();
          return;
        }
        _decoded[chunk[j]] = image;
        while (_decoded.length > _decodedCacheCapacity) {
          _decoded.remove(_decoded.keys.first)?.dispose();
        }
      }
    }
  }

  Future<ui.Image?> _decodeFromDisk(TileCoord coord) async {
    final bytes = await _readFromDisk(coord);
    if (bytes == null) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      _logger.error('Failed to decode tile $coord: $e');
      return null;
    }
  }

  @override
  ui.Image? imageFor(TileCoord coord) => _decoded[coord];

  void dispose() {
    _disposed = true;
    for (final image in _decoded.values) {
      image.dispose();
    }
    _decoded.clear();
  }

  Future<_TileDiskOutcome> _ensureOnDisk(TileCoord coord) async {
    final file = await _fileFor(coord);
    try {
      if (await file.exists()) {
        final age = DateTime.now().difference(await file.lastModified());
        if (age < cacheTtl && await file.length() > 0) {
          return _TileDiskOutcome.cached;
        }
      }
    } catch (_) {
      // Treat unreadable cache entries as missing.
    }

    final bytes = await _api.fetchTile(coord, styleId: _style.styleId);
    if (bytes == null || bytes.isEmpty) return _TileDiskOutcome.failed;
    try {
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      _logger.error('Failed to cache tile $coord: $e');
      // The bytes were fetched; a cache-write failure shouldn't fail the
      // prefetch, but the tile won't survive for the render loop either,
      // so report it as failed unless we can hold it in memory.
      return _TileDiskOutcome.failed;
    }
    return _TileDiskOutcome.downloaded;
  }

  Future<Uint8List?> _readFromDisk(TileCoord coord) async {
    try {
      final file = await _fileFor(coord);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (e) {
      _logger.error('Failed to read tile $coord: $e');
      return null;
    }
  }

  Future<File> _fileFor(TileCoord coord) async {
    final dir = await _ensureCacheDir();
    return File(p.join(dir.path, '${coord.cacheKey}.img'));
  }

  Future<Directory> _ensureCacheDir() async {
    final existing = _cacheDir;
    if (existing != null) return existing;
    final base = await _cacheDirectoryProvider();
    // Per-style subdirectory: the same z/x/y means different imagery per
    // style, so they must never share cache entries.
    final dir = Directory(p.join(base.path, cacheSubdirectory, _style.name));
    await dir.create(recursive: true);
    _cacheDir = dir;
    return dir;
  }

  /// Keeps the shared tile cache bounded by evicting oldest files first.
  Future<void> _trimDiskCache() async {
    try {
      final dir = await _ensureCacheDir();
      final files = <({File file, DateTime modified, int size})>[];
      var totalBytes = 0;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        files.add((file: entity, modified: stat.modified, size: stat.size));
        totalBytes += stat.size;
      }
      if (totalBytes <= maxCacheBytes) return;
      files.sort((a, b) => a.modified.compareTo(b.modified));
      for (final entry in files) {
        if (totalBytes <= maxCacheBytes) break;
        await entry.file.delete();
        totalBytes -= entry.size;
      }
    } catch (e) {
      _logger.error('Tile cache trim failed: $e');
    }
  }
}

/// How a tile was satisfied during prefetch — for timing diagnostics.
enum _TileDiskOutcome { cached, downloaded, failed }
