import 'package:flutter/services.dart' show rootBundle;

class IataIcoaConverter {
  static Future<Map<String, String>> loadIataToIcaoMap() async {
    final Map<String, String> iataToIcao = {};
    final raw = await rootBundle.loadString('assets/data/iata_airlines.csv');
    final lines = raw.split('\n');

    for (final line in lines) {
      final parts = line.split('^').map((p) => p.trim().toUpperCase()).toList();
      if (parts.length >= 2) {
        final icao = parts[0]; // e.g. U2
        final iata = parts[1]; // e.g. EZY
        if (iata.isNotEmpty && icao.isNotEmpty) {
          iataToIcao[iata] = icao; // ✅ IATA → ICAO
        }
      }
    }
    return iataToIcao;
  }

  static Future<String> convertIataFlight(String iataFlight) async {
    final map = await loadIataToIcaoMap();
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(iataFlight.toUpperCase().trim());
    if (match == null) return iataFlight;

    final iata = match.group(1);
    final number = match.group(2);

    final icao = map[iata];
    return icao != null ? '$icao$number' : iataFlight;
  }
}
