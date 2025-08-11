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

    try {
      final resp = await client.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final bodyBytes = resp.bodyBytes;

        // Check if response is not empty
        if (bodyBytes.isNotEmpty) {
          init.sendPort.send(TileData(tile.z, tile.x, tile.y, bodyBytes));
          downloaded++;
        } else {
          _isolateLog('Empty response for tile ${tile.z}/${tile.x}/${tile.y}');
          failed++;
        }
      } else {
        _isolateLog(
          'HTTP ${resp.statusCode} for tile ${tile.z}/${tile.x}/${tile.y}',
        );
        failed++;
      }
    } catch (e) {
      _isolateLog('Error downloading tile ${tile.z}/${tile.x}/${tile.y}: $e');
      failed++;
    }
  }
  client.close();

  _isolateLog('Worker completed: $downloaded downloaded, $failed failed');

  init.sendPort.send('done');
}

/// Helper method for isolate logging that only prints in debug mode
void _isolateLog(String message) {
  if (kDebugMode) {
    // Keep print in isolate for simplicity and to avoid extra dependencies
    // Isolate logs are debug-only
    print('[VectorTilesDownloader] $message');
  }
}
