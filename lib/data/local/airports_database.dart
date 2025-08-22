import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../entity/airport.dart';
import '../../logger.dart';

/// Interface for airports database operations
abstract class IAirportsDb {
  /// Initialize the airports database by loading CSV data
  Future<void> initialize();

  /// Search airports by name or city (case-insensitive)
  List<Airport> search(String query);

  /// Check if database is initialized
  bool get isInitialized;
}

/// Local airports database for offline airport data lookup
class AirportsDatabase implements IAirportsDb {
  static AirportsDatabase? _instance;
  final _logger = Logger('AirportsDatabase');
  List<Airport> _airports = [];
  bool _isInitialized = false;

  AirportsDatabase._();

  /// Get singleton instance
  static AirportsDatabase get instance {
    _instance ??= AirportsDatabase._();
    return _instance!;
  }

  /// Initialize the airports database by loading CSV data
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.log('Initializing airports database...');

      // Load the CSV file from Flutter assets
      final String csvData = await rootBundle.loadString(
        'assets/data/airports.csv',
      );
      final lines = csvData.split('\n');
      _logger.log('Found ${lines.length} lines in airports CSV');

      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        try {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final parts = line.split(',');
          if (parts.length < 18) {
            _logger.log(
              'Skipping invalid line $i: insufficient data (${parts.length} columns, need at least 18)',
            );
            continue;
          }

          // Parse CSV columns: id,ident,type,name,latitude_deg,longitude_deg,elevation_ft,continent,iso_country,iso_region,municipality,scheduled_service,icao_code,iata_code,gps_code,local_code,home_link,wikipedia_link,keywords
          final iata = parts[13].trim().toUpperCase(); // iata_code column
          final icao = parts[12].trim().toUpperCase(); // icao_code column
          final name = parts[3].trim(); // name column
          final city = parts[10].trim(); // municipality column
          final country = parts[8].trim(); // iso_country column
          final lat = double.tryParse(parts[4].trim()); // latitude_deg column
          final lon = double.tryParse(parts[5].trim()); // longitude_deg column
          final wiki = parts[17].trim(); // wikipedia_link column

          if (name.isEmpty || lat == null || lon == null) {
            _logger.log(
              'Skipping invalid line $i: missing required data (Name: "$name", Lat: $lat, Lon: $lon)',
            );
            continue;
          }

          final airport = Airport(
            name: name,
            latLon: LatLng(lat, lon),
            city: city,
            country: country,
            iataCode: iata,
            icaoCode: icao,
            wikipediaUrl: wiki,
          );

          _airports.add(airport);

          if (i % 1000 == 0) {
            _logger.log('Processed $i airports...');
          }
        } catch (e) {
          _logger.error('Error parsing line $i: $e');
          continue;
        }
      }

      _isInitialized = true;
      _logger.log('Successfully loaded ${_airports.length} airports');
    } catch (e) {
      _logger.error('Error initializing airports database: $e');
    }
  }

  /// Search airports by name or city (case-insensitive)
  @override
  List<Airport> search(String query) {
    if (!_isInitialized) {
      _logger.log('Database not initialized, call initialize() first');
      return [];
    }

    final upperQuery = query.toUpperCase();
    final results = <Airport>[];

    for (final airport in _airports) {
      if (airport.airportName.toUpperCase().contains(upperQuery) ||
          airport.city.toUpperCase().contains(upperQuery) ||
          airport.displayCode.toUpperCase().contains(upperQuery)) {
        results.add(airport);
      }
    }

    _logger.log('Search for "$query" returned ${results.length} results');
    return results;
  }

  /// Check if database is initialized
  @override
  bool get isInitialized => _isInitialized;
}
