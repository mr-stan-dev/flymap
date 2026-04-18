import 'package:flymap/entity/user_flight_prefs.dart';
import 'package:flymap/repository/user_flight_prefs_storage.dart';

class UserFlightPrefsRepository {
  UserFlightPrefsRepository({required UserFlightPrefsStorage storage})
    : _storage = storage;

  final UserFlightPrefsStorage _storage;

  Future<UserFlightPrefs> getPrefs() async {
    return _storage.loadPrefs();
  }
}
