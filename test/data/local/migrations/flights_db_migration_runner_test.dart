import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/migrations/flights_db_migration_runner.dart';
import 'package:flymap/data/local/migrations/flights_db_migration_v1_to_v2.dart';
import 'package:sembast/sembast_memory.dart';

class _RecordingCrashlytics implements AppCrashlytics {
  final errors = <Object>[];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setContext({
    String? screen,
    int? routeLengthKm,
    String? mapDetail,
    String? flightNumber,
    int? articlesSelectedCount,
    String? downloadStage,
  }) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    errors.add(error);
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}
}

void main() {
  late Database db;
  late AppDatabase appDb;
  late _RecordingCrashlytics crashlytics;

  // No ConnectivityChecker: the runner runs migrations unconditionally. This
  // test constructing it with no network dependency IS the regression guard
  // for the old offline-gated behavior.
  FlightsDbMigrationRunner runner() => FlightsDbMigrationRunner(
    database: appDb,
    migrations: [FlightsDbMigrationV1ToV2(database: appDb)],
    crashlytics: crashlytics,
  );

  setUp(() async {
    db = await newDatabaseFactoryMemory().openDatabase('migration_test.db');
    appDb = AppDatabase.test(database: db);
    crashlytics = _RecordingCrashlytics();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int?> schemaVersion() async {
    final record = await appDb.migrationsStore
        .record('flights_db_schema')
        .get(db);
    return record?['version'] as int?;
  }

  Future<void> seedLegacyFlight(String id, {String path = '/m.mbtiles'}) {
    return appDb.flightsStore.record(id).put(db, {
      'id': id,
      'maps': [
        {
          'filePath': path,
          'layer': 'streets',
          'sizeBytes': 1234,
          'downloadedAt': '2026-07-01T00:00:00Z',
        },
      ],
    });
  }

  test('migrates a v1 flight with no network: backfills assets, advances to v2',
      () async {
    await seedLegacyFlight('flight-1', path: '/maps/flight-1_streets.mbtiles');

    await runner().migrateIfNeeded();

    expect(crashlytics.errors, isEmpty);
    expect(await schemaVersion(), 2);
    final mapAssets = (await appDb.flightAssetsStore.find(db))
        .where((a) => a.value['type'] == 'map')
        .toList();
    expect(mapAssets, hasLength(1));
    expect(mapAssets.first.value['flightId'], 'flight-1');
    expect(
      mapAssets.first.value['filePath'],
      '/maps/flight-1_streets.mbtiles',
    );
  });

  test('is idempotent: a second run neither re-applies nor duplicates',
      () async {
    await seedLegacyFlight('flight-1');
    await runner().migrateIfNeeded();
    final countAfterFirst = (await appDb.flightAssetsStore.find(db)).length;

    // A fresh runner instance sees version 2 and skips the migration.
    await runner().migrateIfNeeded();

    expect(await schemaVersion(), 2);
    expect((await appDb.flightAssetsStore.find(db)).length, countAfterFirst);
  });

  test('a fresh install with no flights still advances the schema version',
      () async {
    await runner().migrateIfNeeded();

    expect(crashlytics.errors, isEmpty);
    expect(await schemaVersion(), 2);
  });

  test('an already-migrated (v2) database does not re-run the backfill',
      () async {
    await appDb.migrationsStore.record('flights_db_schema').put(db, {
      'version': 2,
    });
    // A legacy-shaped flight that WOULD be backfilled if the migration ran.
    await seedLegacyFlight('flight-2');

    await runner().migrateIfNeeded();

    expect(await appDb.flightAssetsStore.find(db), isEmpty);
  });
}
