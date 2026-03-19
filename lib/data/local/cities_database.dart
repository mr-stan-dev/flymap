import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flymap/entity/city.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';

class CitiesDatabase {
  static CitiesDatabase? _instance;
  final _logger = Logger('CitiesDatabase');
  List<City> _cities = [];
  bool _isInitialized = false;

  CitiesDatabase._();

  /// Get singleton instance
  static CitiesDatabase get instance {
    _instance ??= CitiesDatabase._();
    return _instance!;
  }

  /// Read-only view of loaded cities
  Iterable<City> get allCities => List.unmodifiable(_cities);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.log('Initializing cities database...');

      // Load the CSV file from Flutter assets
      final String csvData = await rootBundle.loadString(
        'assets/data/cities_50000.csv',
      );

      if (csvData.isEmpty) {
        _isInitialized = true;
        return;
      }

      // Offload heavy parsing to a background isolate
      _cities = await compute(_parseCities, csvData);

      _isInitialized = true;
      _logger.log('Successfully loaded ${_cities.length} cities');
    } catch (e) {
      _logger.error('Error initializing cities database: $e');
    }
  }

  /// Static method to parse cities in a separate isolate
  static List<City> _parseCities(String csvData) {
    // Parse CSV robustly
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
      fieldDelimiter: ';',
    ).convert(csvData);

    if (rows.isEmpty) return [];

    // Headers reference based on previous filter_cities.py output:
    // ['Name', 'ASCII Name', 'Country Code', 'Country name EN', 'Country Code 2', 
    //  'Population', 'Elevation', 'DIgital Elevation Model', 'Timezone', 'LABEL EN', 'Coordinates']
    
    final cities = <City>[];

    // Skip header row
    final headerRow = rows[0];
    final coordIndex = headerRow.indexOf('Coordinates');
    
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= coordIndex) continue;

      final parts = row.map((e) => (e ?? '').toString().trim()).toList();

      final name = parts[0];
      final asciiName = parts[1];
      final countryCode = parts[2];
      final popStr = parts[5];
      final elevationStr = parts[6];
      final timezone = parts[8];
      final coordStr = parts[10];

      try {
        final population = int.tryParse(popStr) ?? 0;
        final elevation = int.tryParse(elevationStr); // Can be null
        
        final coordParts = coordStr.split(',');
        if (coordParts.length != 2) continue;
        
        final lat = double.parse(coordParts[0].trim());
        final lon = double.parse(coordParts[1].trim());

        final city = City(
          name: name,
          asciiName: asciiName,
          countryCode: countryCode,
          population: population,
          elevation: elevation,
          timezone: timezone,
          latLon: LatLng(lat, lon),
        );

        cities.add(city);
      } catch (e) {
        // Skip invalid rows silently or log debug
        continue;
      }
    }
    return cities;
  }

  /// Get cities inside the corridor polygon defined by [corridor].
  List<City> getCitiesInCorridor(List<LatLng> corridor) {
    if (!_isInitialized) {
      _logger.log('Database not initialized, returning empty list');
      return [];
    }

    if (corridor.length < 3) return [];

    final results = <City>[];

    // 1. Calculate Bounding Box of the corridor polygon
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLon = 180.0;
    double maxLon = -180.0;

    for (final point in corridor) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }

    // Handle dateline crossing in bounding box if needed.
    // Simple heuristic: if corridor spans practically the whole world longitude-wise?
    // Usually corridors are local. If minLon and maxLon are far apart (e.g., -170 and 170),
    // we might have a crossing.
    // For now, using standard min/max check.
    
    // 2. Iterate cities
    for (final city in _cities) {
      final lat = city.latLon.latitude;
      final lon = city.latLon.longitude;

      // Fast fail Bounding Box Check
      if (lat < minLat || lat > maxLat || lon < minLon || lon > maxLon) {
        continue;
      }

      // 3. Point in Polygon Check (Ray Casting)
      if (_isPointInPolygon(city.latLon, corridor)) {
        results.add(city);
      }
    }
    
    return results;
  }

  /// Ray Casting algorithm to check if [point] is inside [polygon].
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * (point.latitude - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        isInside = !isInside;
      }
      j = i;
    }
    
    return isInside;
  }
}
