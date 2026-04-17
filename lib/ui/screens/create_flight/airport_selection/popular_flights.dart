import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/entity/airport.dart';

Future<List<Airport>> loadPopularAirports({
  AirportsDatabase? airportsDatabase,
}) async {
  final db = airportsDatabase ?? AirportsDatabase.instance;
  await db.initialize();

  // Curated popular airports by IATA code.
  const popularCodes = <String>[
    'LHR',
    'CDG',
    'AMS',
    'MAD',
    'FCO',
    'FRA',
    'JFK',
    'LAX',
    'SFO',
    'MIA',
    'SIN',
    'DXB',
  ];

  final airports = <Airport>[];
  for (final code in popularCodes) {
    final airport = db.findByCode(code);
    if (airport != null) {
      airports.add(airport);
    }
  }
  return airports;
}
