import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/entity/airport.dart';

Future<List<Map<String, Airport>>> loadPopularFlights() async {
  final db = AirportsDatabase.instance;
  await db.initialize();

  // Define pairs by IATA codes primarily (unique and user-facing)
  const pairs = <List<String>>[
    ['LTN', 'BER'],
    ['CDG', 'FCO'],
    ['AMS', 'MAD'],
    ['LAX', 'SFO'],
    ['JFK', 'MIA'],
  ];

  final result = <Map<String, Airport>>[];
  for (final pair in pairs) {
    final dep = db.findByCode(pair[0]);
    final arr = db.findByCode(pair[1]);
    print("dep: ${pair[0]} ${dep?.name}");
    print("arr: ${pair[1]} ${arr?.name}");
    if (dep != null && arr != null) {
      result.add({'departure': dep, 'arrival': arr});
    }
  }
  return result;
}
