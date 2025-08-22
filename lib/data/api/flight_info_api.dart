import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/data/api/flight_info_api_mapper.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';

class FlightInfoApi {
  final functions = FirebaseFunctions.instance;
  static const _promptVersion = 3;
  static const _getOverviewFunction = 'get_flight_overview';
  final _logger = Logger('GetPoiApi');

  final FlightInfoApiMapper _mapper;

  FlightInfoApi({required FlightInfoApiMapper apiMapper}) : _mapper = apiMapper;

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
        'prompt_version' : _promptVersion.toString(),
      },
    );
    final map = jsonDecode(result.data).cast<String, dynamic>();
    return _mapper.toFlightInfo(map);
  }

}
