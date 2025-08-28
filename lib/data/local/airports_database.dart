import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';

class AirportsDatabase {
  static AirportsDatabase? _instance;
  final _logger = Logger('AirportsDatabase');
  final List<Airport> _airports = [];
  bool _isInitialized = false;

  AirportsDatabase._();

  /// Get singleton instance
  static AirportsDatabase get instance {
    _instance ??= AirportsDatabase._();
    return _instance!;
  }

  /// Read-only view of loaded airports
  Iterable<Airport> get allAirports => List.unmodifiable(_airports);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.log('Initializing airports database...');

      // Load the CSV file from Flutter assets
      final String csvData = await rootBundle.loadString(
        'assets/data/airports.csv',
      );

      // Parse CSV robustly (handles quotes and commas in fields)
      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(csvData);
      _logger.log('Found ${rows.length} rows in airports CSV');
      if (rows.isEmpty) {
        _isInitialized = true;
        return;
      }

      // OurAirports header columns reference
      // [0:id, 1:ident, 2:type, 3:name, 4:latitude_deg, 5:longitude_deg,
      //  6:elevation_ft, 7:continent, 8:iso_country, 9:iso_region,
      // 10:municipality, 11:scheduled_service, 12:icao_code, 13:iata_code,
      // 14:gps_code, 15:local_code, 16:home_link, 17:wikipedia_link, 18:keywords]
      for (int i = 1; i < rows.length; i++) {
        final parts = rows[i].map((e) => (e ?? '').toString().trim()).toList();

        final ident = parts[1].toUpperCase(); // e.g., EGGW
        final name = parts[3];
        final latStr = parts[4];
        final lonStr = parts[5];
        final isoCountry = parts[8].toUpperCase();
        final municipality = parts[10];
        final icaoFromCol = parts[12].toUpperCase(); // icao_code column
        final iata = parts[13].toUpperCase();
        final gpsCode = parts[14].toUpperCase(); // gps_code column
        final wiki = parts[17]; // wikipedia_link column

        final lat = double.parse(latStr);
        final lon = double.parse(lonStr);

        // Prefer ICAO from 'icao_code' (column 12), then 'ident' (column 1), then 'gps_code' (column 14)
        String icao = '';
        if (icaoFromCol.length == 4) {
          icao = icaoFromCol;
        } else if (ident.length == 4) {
          icao = ident;
        } else if (gpsCode.length == 4) {
          icao = gpsCode;
        }

        final airport = Airport(
          name: name,
          latLon: LatLng(lat, lon),
          city: municipality,
          countryCode: isoCountry,
          iataCode: iata,
          icaoCode: icao,
          wikipediaUrl: wiki,
        );

        _airports.add(airport);
      }

      _isInitialized = true;
      _logger.log('Successfully loaded ${_airports.length} airports');
    } catch (e) {
      _logger.error('Error initializing airports database: $e');
    }
  }

  List<Airport> search(String query) {
    if (!_isInitialized) {
      _logger.log('Database not initialized, call initialize() first');
    }

    final upperQuery = query.toUpperCase();
    final results = <Airport>[];

    for (final airport in _airports) {
      if (airport.name.toUpperCase().contains(upperQuery) ||
          airport.city.toUpperCase().contains(upperQuery) ||
          airport.displayCode.toUpperCase().contains(upperQuery)) {
        results.add(airport);
      }
    }

    _logger.log('Search for "$query" returned ${results.length} results');
    return results;
  }

  Airport? findByCode(String code) {
    if (!_isInitialized) return null;
    final upper = code.toUpperCase();
    for (final a in _airports) {
      if (a.iataCode.toUpperCase() == upper ||
          a.icaoCode.toUpperCase() == upper) {
        return a;
      }
    }
    return null;
  }
}
