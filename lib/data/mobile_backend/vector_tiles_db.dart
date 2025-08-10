import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';

import '../../logger.dart';

class VectorTilesDb {
  final Logger _logger = const Logger('VectorTilesDb');

  Future<void> createMbtilesSchema(Database db, int version) async {
    _logger.log('Creating MBTiles schema...');
    await db.execute('PRAGMA user_version = 2;');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS tile_index ON tiles (zoom_level, tile_column, tile_row);',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS metadata (name TEXT, value TEXT);',
    );
    _logger.log('MBTiles schema created.');
  }

  Future<void> insertTile(Database db, TileRecord data) async {
    try {
      // MBTiles expects TMS scheme (row flipped)
      final tmsRow = (math.pow(2, data.z).toInt() - 1) - data.y;

      await db.insert('tiles', {
        'zoom_level': data.z,
        'tile_column': data.x,
        'tile_row': tmsRow,
        'tile_data': data.bytes,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      _logger.error(
        'Database error inserting tile ${data.z}/${data.x}/${data.y}: $e',
      );
      rethrow;
    }
  }
}

class TileRecord {
  final int z;
  final int x;
  final int y;
  final List<int> bytes;

  TileRecord(this.z, this.x, this.y, this.bytes);
}
