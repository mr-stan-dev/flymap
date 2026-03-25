import 'package:shared_preferences/shared_preferences.dart';

class FavoriteAirportsRepository {
  static const _kFavoriteAirportCodes = 'create_flight.favorite_airport_codes';
  static const _maxFavorites = 20;

  Future<List<String>> getFavoriteCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_kFavoriteAirportCodes) ?? const [];
    return stored.map(_normalizeCode).where((code) => code.isNotEmpty).toList();
  }

  Future<void> toggleFavorite(String code) async {
    final normalized = _normalizeCode(code);
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await getFavoriteCodes();
    if (current.contains(normalized)) {
      current.remove(normalized);
    } else {
      current.insert(0, normalized);
      if (current.length > _maxFavorites) {
        current.removeRange(_maxFavorites, current.length);
      }
    }
    await prefs.setStringList(_kFavoriteAirportCodes, current);
  }

  Future<void> addFavorite(String code) async {
    final normalized = _normalizeCode(code);
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await getFavoriteCodes();
    current.remove(normalized);
    current.insert(0, normalized);
    if (current.length > _maxFavorites) {
      current.removeRange(_maxFavorites, current.length);
    }
    await prefs.setStringList(_kFavoriteAirportCodes, current);
  }

  Future<void> touchFavorite(String code) async {
    final normalized = _normalizeCode(code);
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await getFavoriteCodes();
    final exists = current.remove(normalized);
    if (!exists) return;

    current.insert(0, normalized);
    await prefs.setStringList(_kFavoriteAirportCodes, current);
  }

  Future<bool> isFavorite(String code) async {
    final normalized = _normalizeCode(code);
    if (normalized.isEmpty) return false;
    final current = await getFavoriteCodes();
    return current.contains(normalized);
  }

  String _normalizeCode(String code) => code.trim().toUpperCase();
}
