import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'tile_utils.dart';

class WorkerInit {
  final List<MapTile> tiles;
  final String template;
  final SendPort sendPort;

  WorkerInit(this.tiles, this.template, this.sendPort);
}

class TileData {
  final int z;
  final int x;
  final int y;
  final Uint8List bytes;

  TileData(this.z, this.x, this.y, this.bytes);
}

const _requestTimeout = Duration(seconds: 12);
const _maxAttempts = 3;
const _retryDelayBaseMs = 300;

/// Worker entrypoint executed in a background isolate.
/// Downloads assigned tiles and sends successful payloads back to main isolate.
void downloadWorker(WorkerInit init) async {
  _isolateLog('Worker started with ${init.tiles.length} tiles');
  final client = http.Client();
  int downloaded = 0;
  int failed = 0;

  for (final tile in init.tiles) {
    final url = init.template
        .replaceAll('{z}', tile.z.toString())
        .replaceAll('{x}', tile.x.toString())
        .replaceAll('{y}', tile.y.toString());

    // Debug first URL
    if (downloaded < 1) {
      _isolateLog('Downloading from URL: $url');
    }

    final bytes = await _downloadTileWithRetry(
      client,
      Uri.parse(url),
      z: tile.z,
      x: tile.x,
      y: tile.y,
    );
    if (bytes != null) {
      init.sendPort.send(TileData(tile.z, tile.x, tile.y, bytes));
      downloaded++;
    } else {
      failed++;
    }
  }
  client.close();

  _isolateLog('Worker completed: $downloaded downloaded, $failed failed');

  init.sendPort.send('done');
}

/// Downloads one tile with timeout + limited retries for transient failures.
Future<Uint8List?> _downloadTileWithRetry(
  http.Client client,
  Uri uri, {
  required int z,
  required int x,
  required int y,
}) async {
  for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
    try {
      final resp = await client.get(uri).timeout(_requestTimeout);
      if (resp.statusCode == 200) {
        final bytes = resp.bodyBytes;
        if (bytes.isNotEmpty) {
          return bytes;
        }
        _isolateLog('Empty response for tile $z/$x/$y');
      } else {
        _isolateLog('HTTP ${resp.statusCode} for tile $z/$x/$y');
        if (!_isRetryableStatus(resp.statusCode)) {
          return null;
        }
      }
    } on TimeoutException {
      _isolateLog('Timeout for tile $z/$x/$y (attempt $attempt/$_maxAttempts)');
    } catch (e) {
      _isolateLog(
        'Error downloading tile $z/$x/$y (attempt $attempt/$_maxAttempts): $e',
      );
    }

    if (attempt < _maxAttempts) {
      final backoff = Duration(milliseconds: _retryDelayBaseMs * attempt);
      await Future.delayed(backoff);
    }
  }

  return null;
}

/// Returns true for HTTP codes where retrying is usually useful.
bool _isRetryableStatus(int statusCode) {
  return statusCode == 408 ||
      statusCode == 429 ||
      (statusCode >= 500 && statusCode <= 599);
}

/// Helper method for isolate logging that only prints in debug mode
void _isolateLog(String message) {
  if (kDebugMode) {
    // Keep print in isolate for simplicity and to avoid extra dependencies
    // Isolate logs are debug-only
    print('[VectorTilesDownloader] $message');
  }
}
