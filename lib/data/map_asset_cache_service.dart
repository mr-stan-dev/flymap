import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flymap/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MapAssetCacheService {
  MapAssetCacheService({
    Future<Directory> Function()? cacheDirectoryProvider,
    Future<List<String>> Function()? assetPathsLoader,
    Future<ByteData> Function(String assetPath)? assetDataLoader,
  }) : _cacheDirectoryProvider =
           cacheDirectoryProvider ?? getApplicationCacheDirectory,
       _assetPathsLoader = assetPathsLoader ?? _loadAssetPathsFromManifest,
       _assetDataLoader = assetDataLoader ?? rootBundle.load;

  static const int cacheVersion = 1;
  // Bump when bundled glyph/sprite contents change without path changes.
  static const String _markerRelativePath = 'assets/.map_asset_cache_ready';
  static const List<String> _assetPrefixes = <String>[
    'assets/glyphs/',
    'assets/sprites/',
  ];

  final Logger _logger = const Logger('MapAssetCacheService');
  final Future<Directory> Function() _cacheDirectoryProvider;
  final Future<List<String>> Function() _assetPathsLoader;
  final Future<ByteData> Function(String assetPath) _assetDataLoader;

  Future<void>? _inFlightEnsureReady;

  Future<void> ensureReady() {
    // Reuse the same in-flight work if multiple map surfaces request assets
    // at the same time. This avoids duplicate file writes on first use.
    final existing = _inFlightEnsureReady;
    if (existing != null) {
      return existing;
    }

    late final Future<void> trackedFuture;
    trackedFuture = _ensureReady().whenComplete(() {
      if (identical(_inFlightEnsureReady, trackedFuture)) {
        _inFlightEnsureReady = null;
      }
    });
    _inFlightEnsureReady = trackedFuture;
    return trackedFuture;
  }

  void ensureReadyInBackground() {
    unawaited(_ensureReadySafely());
  }

  Future<void> _ensureReadySafely() async {
    try {
      await ensureReady();
    } catch (error) {
      _logger.error('Failed to prepare map asset cache: $error');
    }
  }

  Future<void> _ensureReady() async {
    final cacheDirectory = await _cacheDirectoryProvider();
    final assetPaths = (await _assetPathsLoader()).toList()..sort();
    if (assetPaths.isEmpty) {
      _logger.log('No map assets found in asset manifest');
      return;
    }

    if (await _isCacheReady(cacheDirectory.path, assetPaths)) {
      _logger.log('Map asset cache is ready');
      return;
    }

    // Materialize bundled Flutter assets into cache because the native
    // map style references them via file:// URLs.
    _logger.log('Preparing map asset cache');
    for (final assetPath in assetPaths) {
      final data = await _assetDataLoader(assetPath);
      final outputFile = File(p.join(cacheDirectory.path, assetPath));
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }

    final markerFile = File(_markerPath(cacheDirectory.path));
    await markerFile.parent.create(recursive: true);
    await markerFile.writeAsString(cacheVersion.toString(), flush: true);
    _logger.log('Map asset cache prepared');
  }

  Future<bool> _isCacheReady(
    String cacheDirectoryPath,
    List<String> assetPaths,
  ) async {
    // The marker prevents partial cache state from being treated as valid after
    // an interrupted copy or after bundled asset contents change.
    final markerFile = File(_markerPath(cacheDirectoryPath));
    if (!await markerFile.exists()) {
      return false;
    }

    final version = await markerFile.readAsString();
    if (version.trim() != cacheVersion.toString()) {
      return false;
    }

    for (final assetPath in assetPaths) {
      if (!await File(p.join(cacheDirectoryPath, assetPath)).exists()) {
        return false;
      }
    }
    return true;
  }

  String _markerPath(String cacheDirectoryPath) {
    return p.join(cacheDirectoryPath, _markerRelativePath);
  }

  static Future<List<String>> _loadAssetPathsFromManifest() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return assetManifest
        .listAssets()
        .where(
          (path) =>
              !path.contains('.DS_Store') &&
              _assetPrefixes.any(path.startsWith),
        )
        .toList();
  }
}
