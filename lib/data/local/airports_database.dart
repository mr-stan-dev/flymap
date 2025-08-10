import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../entity/airport.dart';
import '../../logger.dart';

/// Interface for airports database operations
abstract class IAirportsDb {
  /// Initialize the airports database by loading CSV data
  Future<void> initialize();

  /// Get airport by IATA code
  Airport? getByIata(String iataCode);

  /// Get airport by ICAO code
  Airport? getByIcao(String icaoCode);

  /// Get airport by any code (tries IATA first, then ICAO)
  Airport? getByCode(String airportCode);

  /// Search airports by name or city (case-insensitive)
  List<Airport> search(String query);

  /// Get all airports
  List<Airport> getAll();

  /// Get database statistics
  Map<String, dynamic> getStats();

  /// Check if database is initialized
  bool get isInitialized;

  /// Clear the database (useful for testing)
  void clear();
}

/// Local airports database for offline airport data lookup
class AirportsDatabase implements IAirportsDb {
  static AirportsDatabase? _instance;
  final _logger = Logger('AirportsDatabase');
  Map<String, Airport> _airportsByIata = {};
  Map<String, Airport> _airportsByIcao = {};
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
          if (parts.length < 14) {
            _logger.log(
              'Skipping invalid line $i: insufficient data (${parts.length} columns, need at least 14)',
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

          if (iata.isEmpty || name.isEmpty || lat == null || lon == null) {
            _logger.log(
              'Skipping invalid line $i: missing required data (IATA: "$iata", Name: "$name", Lat: $lat, Lon: $lon)',
            );
            continue;
          }

          final airport = Airport(
            code: iata,
            name: name,
            latLon: LatLng(lat, lon),
            city: city,
            country: country,
          );

          // Store by IATA code (only if not empty)
          if (iata.isNotEmpty) {
            _airportsByIata[iata] = airport;
          }

          // Store by ICAO code if available
          if (icao.isNotEmpty) {
            _airportsByIcao[icao] = airport;
          }

          if (i % 1000 == 0) {
            _logger.log('Processed $i airports...');
          }
        } catch (e) {
          _logger.error('Error parsing line $i: $e');
          continue;
        }
      }

      _isInitialized = true;
      _logger.log(
        'Successfully loaded ${_airportsByIata.length} airports by IATA',
      );
      _logger.log(
        'Successfully loaded ${_airportsByIcao.length} airports by ICAO',
      );
    } catch (e) {
      _logger.error('Error initializing airports database: $e');
    }
  }

  /// Get airport by IATA code
  @override
  Airport? getByIata(String iataCode) {
    if (!_isInitialized) {
      _logger.log('Database not initialized, call initialize() first');
      return null;
    }

    final airport = _airportsByIata[iataCode.toUpperCase()];
    if (airport != null) {
      _logger.log('Found airport by IATA $iataCode: ${airport.airportName}');
    } else {
      _logger.log('Airport not found by IATA: $iataCode');
    }
    return airport;
  }

  /// Get airport by ICAO code
  @override
  Airport? getByIcao(String icaoCode) {
    if (!_isInitialized) {
      _logger.log('Database not initialized, call initialize() first');
      return null;
    }

    final airport = _airportsByIcao[icaoCode.toUpperCase()];
    if (airport != null) {
      _logger.log('Found airport by ICAO $icaoCode: ${airport.airportName}');
    } else {
      _logger.log('Airport not found by ICAO: $icaoCode');
    }
    return airport;
  }

  /// Get airport by any code (tries IATA first, then ICAO)
  @override
  Airport? getByCode(String airportCode) {
    if (!_isInitialized) {
      _logger.log('Database not initialized, call initialize() first');
      return null;
    }

    final upperCode = airportCode.toUpperCase();

    // Try IATA first
    var airport = _airportsByIata[upperCode];
    if (airport != null) {
      _logger.log('Found airport by IATA $airportCode: ${airport.airportName}');
      return airport;
    }

    // Try ICAO
    airport = _airportsByIcao[upperCode];
    if (airport != null) {
      _logger.log('Found airport by ICAO $airportCode: ${airport.airportName}');
      return airport;
    }

    _logger.log('Airport not found by code: $airportCode');
    return null;
  }

  /// Search airports by name or city (case-insensitive)
  @override
  List<Airport> search(String query) {
    if (!_isInitialized) {
      _logger.log(
        'Database not initialized, call initialize() first',
      );
      return [];
    }

    final upperQuery = query.toUpperCase();
    final results = <Airport>[];

    for (final airport in _airportsByIata.values) {
      if (airport.airportName.toUpperCase().contains(upperQuery) ||
          airport.city.toUpperCase().contains(upperQuery) ||
          airport.code.toUpperCase().contains(upperQuery)) {
        results.add(airport);
      }
    }

    _logger.log(
      'Search for "$query" returned ${results.length} results',
    );
    return results;
  }

  /// Get all airports
  @override
  List<Airport> getAll() {
    if (!_isInitialized) {
      _logger.log(
        'Database not initialized, call initialize() first',
      );
      return [];
    }

    return _airportsByIata.values.toList();
  }

  /// Get database statistics
  @override
  Map<String, dynamic> getStats() {
    return {
      'initialized': _isInitialized,
      'totalAirports': _airportsByIata.length,
      'airportsWithIcao': _airportsByIcao.length,
      'iataCodes': _airportsByIata.keys.toList(),
      'icaoCodes': _airportsByIcao.keys.toList(),
    };
  }

  /// Check if database is initialized
  @override
  bool get isInitialized => _isInitialized;

  /// Clear the database (useful for testing)
  @override
  void clear() {
    _airportsByIata.clear();
    _airportsByIcao.clear();
    _isInitialized = false;
    _logger.log('Database cleared');
  }
}
