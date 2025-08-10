import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;
  static StoreRef<String, Map<String, dynamic>>? _flightsStore;
  static StoreRef<String, Map<String, dynamic>>? _mapsStore;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  /// Initialize the database
  Future<void> initialize() async {
    if (_database == null) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDocDir.path, 'flymap.db');
      _database = await databaseFactoryIo.openDatabase(dbPath);

      // Initialize stores
      _flightsStore = stringMapStoreFactory.store('flights');
      _mapsStore = stringMapStoreFactory.store('maps');
    }
  }

  /// Get the database instance
  Database get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Get the flights store
  StoreRef<String, Map<String, dynamic>> get flightsStore {
    if (_flightsStore == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _flightsStore!;
  }

  /// Get the maps store
  StoreRef<String, Map<String, dynamic>> get mapsStore {
    if (_mapsStore == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _mapsStore!;
  }

  /// Close the database
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _flightsStore = null;
    _mapsStore = null;
  }
}
