import 'package:shared_preferences/shared_preferences.dart';

class RecentAirportsRepository {
  static const _kRecentAirportCodes = 'create_flight.recent_airport_codes';
  static const _maxRecent = 10;

  Future<List<String>> getRecentCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_kRecentAirportCodes) ?? const [];
    return stored.map(_normalizeCode).where((code) => code.isNotEmpty).toList();
  }

  Future<void> addRecent(String code) async {
    final normalized = _normalizeCode(code);
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentCodes();
    current.remove(normalized);
    current.insert(0, normalized);
    if (current.length > _maxRecent) {
      current.removeRange(_maxRecent, current.length);
    }
    await prefs.setStringList(_kRecentAirportCodes, current);
  }

  Future<void> addRecents(Iterable<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentCodes();
    for (final code in codes) {
      final normalized = _normalizeCode(code);
      if (normalized.isEmpty) continue;
      current.remove(normalized);
      current.insert(0, normalized);
    }
    if (current.length > _maxRecent) {
      current.removeRange(_maxRecent, current.length);
    }
    await prefs.setStringList(_kRecentAirportCodes, current);
  }

  String _normalizeCode(String code) => code.trim().toUpperCase();
}
