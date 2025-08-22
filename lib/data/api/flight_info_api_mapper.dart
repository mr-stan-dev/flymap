import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_poi.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';

class FlightInfoApiMapper {

  FlightInfo toFlightInfo(Map<String, dynamic> map) {
    final dynamic list = map['poi'];
    final pois = (list is List)
        ? list
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(_toFlightPoi)
        .nonNulls
        .toList()
        : <FlightPoi>[];
    final overview = (map['overview'] ?? '').toString();
    return FlightInfo(overview, pois);
  }

  FlightPoi? _toFlightPoi(Map<String, dynamic> map) {
    final dynamic coordinates = map['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final double? lat = _toDouble(coordinates[0]);
      final double? lon = _toDouble(coordinates[1]);
      if (lat != null && lon != null) {
        return FlightPoi(
          coordinates: LatLng(lat, lon),
          type: (map['type'] ?? '').toString(),
          description: (map['description'] ?? '')
              .toString(),
          name: (map['name'] ?? '').toString(),
          flyView: (map['fly_view'] ?? '').toString(),
          wiki: (map['wiki'] ?? '').toString(),
        );
      }
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
