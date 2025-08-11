import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../logger.dart';

class MbtilesVerifier {
  static final _logger = Logger('MbtilesVerifier');

  static Future<bool> verifyMbtilesFile(String filePath) async {
    _logger.log('Verifying MBTiles file: $filePath');

    final file = File(filePath);
    if (!await file.exists()) {
      _logger.error('File does not exist!');
      return false;
    }

    final fileSize = await file.length();
    _logger.log('File size: ${(fileSize / 1024).toStringAsFixed(2)}KB');

    try {
      final db = await openDatabase(filePath, readOnly: true);

      // Check if tables exist
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['table'],
        columns: ['name'],
      );

      _logger.log('Tables found: ${tables.map((t) => t['name']).join(', ')}');

      // Check tiles table structure
      final tilesColumns = await db.rawQuery('PRAGMA table_info(tiles)');
      _logger.log('Tiles table columns:');
      for (final col in tilesColumns) {
        _logger.log('  - ${col['name']} (${col['type']})');
      }

      // Count total tiles
      final tileCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tiles'),
      );
      _logger.log('Total tiles: $tileCount');

      // Show zoom level distribution
      final zoomStats = await db.rawQuery('''
        SELECT zoom_level, COUNT(*) as count 
        FROM tiles 
        GROUP BY zoom_level 
        ORDER BY zoom_level
      ''');

      _logger.log('Tiles by zoom level:');
      for (final stat in zoomStats) {
        _logger.log('  - Zoom ${stat['zoom_level']}: ${stat['count']} tiles');
      }

      // Show sample tile data
      final sampleTile = await db.query(
        'tiles',
        limit: 1,
        columns: [
          'zoom_level',
          'tile_column',
          'tile_row',
          'length(tile_data) as data_size',
        ],
      );

      if (sampleTile.isNotEmpty) {
        final tile = sampleTile.first;
        _logger.log('Sample tile:');
        _logger.log('  - Zoom: ${tile['zoom_level']}');
        _logger.log('  - Column: ${tile['tile_column']}');
        _logger.log('  - Row: ${tile['tile_row']}');
        _logger.log('  - Data size: ${tile['data_size']} bytes');
      }

      // Check metadata table
      final metadata = await db.query('metadata');
      if (metadata.isNotEmpty) {
        _logger.log('Metadata:');
        for (final meta in metadata) {
          _logger.log('  - ${meta['name']}: ${meta['value']}');
        }
      }

      await db.close();
      _logger.log('Verification completed successfully!');
      return true;
    } catch (e) {
      _logger.error('Verification failed: $e');
      return false;
    }
  }

  static Future<void> verifyTileContent(
    String filePath,
    int zoom,
    int x,
    int y,
  ) async {
    _logger.log('Checking tile content for $zoom/$x/$y');

    try {
      final db = await openDatabase(filePath, readOnly: true);

      // Get tile data
      final tiles = await db.query(
        'tiles',
        where: 'zoom_level = ? AND tile_column = ? AND tile_row = ?',
        whereArgs: [zoom, x, y],
      );

      if (tiles.isEmpty) {
        _logger.log('Tile $zoom/$x/$y not found!');
      } else {
        final tile = tiles.first;
        final dataSize = (tile['tile_data'] as List<int>).length;
        _logger.log('Tile $zoom/$x/$y found:');
        _logger.log('  - Data size: $dataSize bytes');
        _logger.log('  - TMS row: ${tile['tile_row']}');

        // Check if it's valid PBF data (should start with specific bytes)
        final data = tile['tile_data'] as List<int>;
        if (data.length > 4) {
          _logger.log(
            '  - First 4 bytes: ${data.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
          );
        }
      }

      await db.close();
    } catch (e) {
      _logger.error('ERROR: $e');
    }
  }
}
