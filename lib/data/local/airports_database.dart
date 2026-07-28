import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';

class AirportsDatabase {
  static AirportsDatabase? _instance;
  final _logger = Logger('AirportsDatabase');
  final List<Airport> _airports = [];

  /// IANA timezone id per airport code (ICAO and IATA keys), from the
  /// build-time-enriched `timezone` CSV column.
  final Map<String, String> _timezoneByCode = {};
  bool _isInitialized = false;
  Future<void>? _initializing;

  AirportsDatabase._();
  AirportsDatabase.test({
    Iterable<Airport> seedAirports = const [],
    Map<String, String> seedTimezones = const {},
  }) {
    _airports.addAll(seedAirports);
    _timezoneByCode.addAll(
      seedTimezones.map((k, v) => MapEntry(k.toUpperCase(), v)),
    );
    _isInitialized = true;
  }

  /// Get singleton instance
  static AirportsDatabase get instance {
    _instance ??= AirportsDatabase._();
    return _instance!;
  }

  /// Read-only view of loaded airports
  Iterable<Airport> get allAirports => List.unmodifiable(_airports);

  Future<void> initialize() async {
    if (_isInitialized) return;
    final inFlightInitialization = _initializing;
    if (inFlightInitialization != null) {
      await inFlightInitialization;
      return;
    }

    _initializing = _initializeInternal();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initializeInternal() async {
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
        _airports.clear();
        _isInitialized = true;
        return;
      }

      final loadedAirports = <Airport>[];

      // OurAirports header columns reference
      // [0:id, 1:ident, 2:type, 3:name, 4:latitude_deg, 5:longitude_deg,
      //  6:elevation_ft, 7:continent, 8:iso_country, 9:iso_region,
      // 10:municipality, 11:scheduled_service, 12:icao_code, 13:iata_code,
      // 14:gps_code, 15:local_code, 16:home_link, 17:wikipedia_link,
      // 18:keywords, 19:timezone (IANA id, tools/airport_timezones)]
      for (int i = 1; i < rows.length; i++) {
        final parts = rows[i].map((e) => (e ?? '').toString().trim()).toList();

        final ident = parts[1].toUpperCase(); // e.g., EGGW
        final type = parts[2];
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
          type: AirportTypeX.fromString(type),
        );

        loadedAirports.add(airport);

        final timezoneId = parts.length > 19 ? parts[19] : '';
        if (timezoneId.isNotEmpty) {
          if (icao.isNotEmpty) _timezoneByCode[icao] = timezoneId;
          if (iata.isNotEmpty) _timezoneByCode[iata] = timezoneId;
        }
      }

      _airports
        ..clear()
        ..addAll(loadedAirports);
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
          airport.displayCode.toUpperCase().contains(upperQuery) ||
          airport.icaoCode.toUpperCase().contains(upperQuery)) {
        results.add(airport);
      }
    }

    results.sort((a, b) {
      final aName = a.name.toUpperCase();
      final aCity = a.city.toUpperCase();
      final aCode = a.displayCode.toUpperCase();
      final aIcao = a.icaoCode.toUpperCase();

      final bName = b.name.toUpperCase();
      final bCity = b.city.toUpperCase();
      final bCode = b.displayCode.toUpperCase();
      final bIcao = b.icaoCode.toUpperCase();

      int getRank(String name, String city, String code, String icao) {
        if (city.startsWith(upperQuery)) return 1;
        if (name.startsWith(upperQuery)) return 2;
        if (code == upperQuery || icao == upperQuery) return 3;
        if (code.startsWith(upperQuery) || icao.startsWith(upperQuery)) {
          return 4;
        }
        if (city.contains(upperQuery)) return 5;
        if (name.contains(upperQuery)) return 6;
        return 7;
      }

      int rankA = getRank(aName, aCity, aCode, aIcao);
      int rankB = getRank(bName, bCity, bCode, bIcao);

      if (rankA != rankB) return rankA.compareTo(rankB);

      int typeRankA = a.type.priority;
      int typeRankB = b.type.priority;

      if (typeRankA != typeRankB) return typeRankA.compareTo(typeRankB);

      // Fallback: alphabetize by city then name
      if (aCity != bCity) return aCity.compareTo(bCity);
      return aName.compareTo(bName);
    });

    _logger.log('Search for "$query" returned ${results.length} results');
    return results;
  }

  /// IANA timezone id for an airport, looked up by ICAO first, then IATA;
  /// null when unknown (DB not loaded, or airport missing from the CSV).
  String? timezoneIdFor({String? icaoCode, String? iataCode}) {
    for (final code in [icaoCode, iataCode]) {
      final key = code?.trim().toUpperCase();
      if (key == null || key.isEmpty) continue;
      final timezoneId = _timezoneByCode[key];
      if (timezoneId != null) return timezoneId;
    }
    return null;
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
