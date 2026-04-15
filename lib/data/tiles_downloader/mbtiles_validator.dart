import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../logger.dart';

class MbtilesValidationResult {
  const MbtilesValidationResult._({required this.isValid, this.errorMessage});

  final bool isValid;
  final String? errorMessage;

  factory MbtilesValidationResult.valid() =>
      const MbtilesValidationResult._(isValid: true);

  factory MbtilesValidationResult.invalid(String errorMessage) =>
      MbtilesValidationResult._(isValid: false, errorMessage: errorMessage);
}

class MbtilesValidator {
  MbtilesValidator._();

  static final Map<String, MbtilesValidationResult> _validationCache = {};

  static Future<MbtilesValidationResult> validate(
    String mbtilesPath, {
    Logger? logger,
  }) async {
    Database? db;
    final log = logger ?? const Logger('MbtilesValidator');

    try {
      final file = File(mbtilesPath);
      final stat = await file.stat();
      final size = stat.size;
      log.log('MBTiles size bytes: $size');
      if (size <= 0) {
        return MbtilesValidationResult.invalid(
          'Offline map file is empty. Please re-download this route.',
        );
      }

      final cacheKey =
          '$mbtilesPath|$size|${stat.modified.millisecondsSinceEpoch}';
      final cached = _validationCache[cacheKey];
      if (cached != null) {
        log.log('Using cached MBTiles validation result');
        return cached;
      }

      db = await openDatabase(mbtilesPath, readOnly: true);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final tableNames = tables
          .map((row) => (row['name'] ?? '').toString())
          .toSet();
      if (!tableNames.contains('tiles')) {
        return MbtilesValidationResult.invalid(
          'Offline map database is invalid (missing tiles table).',
        );
      }

      final tileCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tiles'),
      );
      if (tileCount == null || tileCount <= 0) {
        return MbtilesValidationResult.invalid(
          'Offline map has no tiles. Please re-download this route.',
        );
      }

      await db.rawQuery(
        'SELECT zoom_level, tile_column, tile_row, length(tile_data) FROM tiles LIMIT 1',
      );
      final sampleMetadata = await db.rawQuery(
        'SELECT name, value FROM metadata LIMIT 5',
      );

      log.log('MBTiles tables: ${tables.map((e) => e['name']).toList()}');
      log.log('MBTiles tile count: $tileCount');
      log.log('MBTiles metadata sample: $sampleMetadata');
      final result = MbtilesValidationResult.valid();
      _validationCache
        ..removeWhere((key, _) => key.startsWith('$mbtilesPath|'))
        ..[cacheKey] = result;
      return result;
    } catch (e) {
      log.error('MBTiles validation failed: $e');
      return MbtilesValidationResult.invalid(
        'Offline map database is corrupted or unreadable. '
        'Please re-download this route.',
      );
    } finally {
      try {
        await db?.close();
      } catch (_) {}
    }
  }
}
