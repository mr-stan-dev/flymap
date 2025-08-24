import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;
  static StoreRef<String, Map<String, dynamic>>? _flightsStore;
  static const _dbName = 'flymap.db';
  static const _flightsStoreName = 'flights';

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_database == null) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDocDir.path, _dbName);
      _database = await databaseFactoryIo.openDatabase(dbPath);

      _flightsStore = stringMapStoreFactory.store(_flightsStoreName);
    }
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

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _flightsStore = null;
  }
}
