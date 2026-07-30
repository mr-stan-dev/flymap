import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

class AppDatabase {
  static AppDatabase? _instance;
  Database? _database;
  StoreRef<String, Map<String, dynamic>>? _flightsStore;
  StoreRef<String, Map<String, dynamic>>? _flightAssetsStore;
  StoreRef<String, Map<String, dynamic>>? _skyCameraMediaStore;
  StoreRef<String, Map<String, dynamic>>? _migrationsStore;
  StoreRef<String, Map<String, dynamic>>? _flightWeatherStore;
  static const _dbName = 'flymap.db';
  static const _flightsStoreName = 'flights';
  static const _flightAssetsStoreName = 'flight_assets';
  static const _skyCameraMediaStoreName = 'sky_camera_media';
  static const _migrationsStoreName = 'migrations';
  static const _flightWeatherStoreName = 'flight_weather';
  static const int schemaVersion = 2;

  AppDatabase._();
  AppDatabase.test({required Database database}) : _database = database {
    _initializeStores();
  }

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_database != null) return;
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocDir.path, _dbName);
    _database = await databaseFactoryIo.openDatabase(dbPath);
    _initializeStores();
  }

  Database get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  StoreRef<String, Map<String, dynamic>> get flightsStore {
    if (_flightsStore == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _flightsStore!;
  }

  StoreRef<String, Map<String, dynamic>> get flightAssetsStore {
    if (_flightAssetsStore == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _flightAssetsStore!;
  }

  StoreRef<String, Map<String, dynamic>> get skyCameraMediaStore {
    if (_skyCameraMediaStore == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _skyCameraMediaStore!;
  }

  StoreRef<String, Map<String, dynamic>> get migrationsStore {
    if (_migrationsStore == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _migrationsStore!;
  }

  /// Last fetched forecast per flight id — kept out of the flight record so
  /// the (potentially few-hundred-KB) sample grid never bloats flight reads.
  StoreRef<String, Map<String, dynamic>> get flightWeatherStore {
    if (_flightWeatherStore == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _flightWeatherStore!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _flightsStore = null;
    _flightAssetsStore = null;
    _skyCameraMediaStore = null;
    _migrationsStore = null;
    _flightWeatherStore = null;
  }

  void _initializeStores() {
    _flightsStore = stringMapStoreFactory.store(_flightsStoreName);
    _flightAssetsStore = stringMapStoreFactory.store(_flightAssetsStoreName);
    _skyCameraMediaStore = stringMapStoreFactory.store(
      _skyCameraMediaStoreName,
    );
    _migrationsStore = stringMapStoreFactory.store(_migrationsStoreName);
    _flightWeatherStore = stringMapStoreFactory.store(_flightWeatherStoreName);
  }
}
