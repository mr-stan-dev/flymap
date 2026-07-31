import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/migrations/flights_db_migration.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/logger.dart';
import 'package:sembast/sembast.dart';

class FlightsDbMigrationRunner {
  FlightsDbMigrationRunner({
    required AppDatabase database,
    required List<FlightsDbMigration> migrations,
    required AppCrashlytics crashlytics,
  }) : _database = database,
       _migrations = migrations,
       _crashlytics = crashlytics;

  static const String _metaRecordKey = 'flights_db_schema';

  final AppDatabase _database;
  final List<FlightsDbMigration> _migrations;
  final AppCrashlytics _crashlytics;
  final Logger _logger = const Logger('FlightsDbMigrationRunner');

  // Runs unconditionally: schema migrations are purely local (they only move
  // data between sembast stores), so gating on connectivity meant offline
  // updaters never advanced their schema — and it added a socket probe to the
  // cold-start path. Network-dependent backfills, if ever added, must gate
  // themselves, not the whole runner.
  Future<void> migrateIfNeeded() async {
    try {
      final db = _database.database;
      final currentVersion = await _readCurrentVersion(db);
      final ordered = [..._migrations]
        ..sort((a, b) => a.targetVersion - b.targetVersion);

      int version = currentVersion;
      for (final migration in ordered) {
        if (migration.targetVersion <= version) continue;
        _logger.log(
          'Running flights DB migration to v${migration.targetVersion}',
        );
        await migration.run(db);
        version = migration.targetVersion;
        await _writeCurrentVersion(db, version);
        _logger.log('Flights DB schema advanced to v$version');
      }
    } catch (error, stack) {
      await _crashlytics.recordError(
        error,
        stack,
        fatal: false,
        reason: 'flights_db_migration_failed',
      );
    }
  }

  Future<int> _readCurrentVersion(Database db) async {
    final raw = await _database.migrationsStore.record(_metaRecordKey).get(db);
    if (raw == null) return 1;
    final v = raw['version'];
    return switch (v) {
      int i => i,
      num n => n.toInt(),
      _ => 1,
    };
  }

  Future<void> _writeCurrentVersion(Database db, int version) async {
    await _database.migrationsStore.record(_metaRecordKey).put(db, {
      'version': version,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
