import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../logger.dart';

class MbtilesVerifier {
  static final _logger = Logger('MbtilesVerifier');

  static Future<int> verifyMbtilesFile(String filePath) async {
    _logger.log('Verifying MBTiles file: $filePath');

    final file = File(filePath);
    if (!await file.exists()) {
      _logger.error('File does not exist!');
      return 0;
    }

    final fileSize = await file.length();
    _logger.log('File size: ${(fileSize / 1024).toStringAsFixed(2)}KB');

    try {
      final db = await openDatabase(filePath, readOnly: true);

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
      return fileSize;
    } catch (e) {
      _logger.error('Verification failed: $e');
      return 0;
    }
  }
}
