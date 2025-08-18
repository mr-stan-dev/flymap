import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_poi.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';

class GetPoiApi {
  final functions = FirebaseFunctions.instance;
  static const _getPoiFunction = 'get_flight_poi';
  static const _getOverviewFunction = 'get_flight_overview';
  final _logger = Logger('GetPoiApi');

  Future<Map<String, dynamic>> getFlightPoi(
    String airportDeparture,
    String airportArrival,
    List<LatLng> waypoints,
  ) async {
    try {
      _logger.log('getRoutePoi with ${waypoints.length} waypoints');
      final result = await functions.httpsCallable(_getPoiFunction).call(
        <String, dynamic>{
          'waypoints': waypoints.map((c) => [c.latitude, c.longitude]).toList(),
          'airport_departure': airportDeparture,
          'airport_arrival': airportArrival,
        },
      );
      return jsonDecode(result.data).cast<String, dynamic>();
    } catch (e) {
      _logger.error('getRoutePoi error: $e');
      return const <String, dynamic>{'poi': []};
    }
  }

  Future<FlightInfo> getFlightOverview(
    String airportDeparture,
    String airportArrival,
    List<LatLng> waypoints,
  ) async {
    _logger.log('getFlightOverview with ${waypoints.length} waypoints');
    final result = await functions.httpsCallable(_getOverviewFunction).call(
      <String, dynamic>{
        'waypoints': waypoints.map((c) => [c.latitude, c.longitude]).toList(),
        'airport_departure': airportDeparture,
        'airport_arrival': airportArrival,
      },
    );
    final map = jsonDecode(result.data).cast<String, dynamic>();
    return _toEntity(map);
  }

  FlightInfo _toEntity(Map<String, dynamic> map) {
    final dynamic list = map['poi'];
    final pois = (list is List)
        ? list
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(FlightPoi.fromMap)
        .toList()
        : <FlightPoi>[];
    final overview = (map['flight_overview'] ?? '').toString();
    return FlightInfo(overview, pois);
  }
}
