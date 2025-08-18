import 'package:flymap/data/api/get_poi_api.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_poi.dart';
import 'package:latlong2/latlong.dart';

/// Use case to fetch flight-related info (e.g., POIs) via backend Cloud Function
class GetFlightInfoUseCase {
  final GetPoiApi _getPoiApi;

  GetFlightInfoUseCase({required GetPoiApi getPoiApi}) : _getPoiApi = getPoiApi;

  /// Fetch flight information (overview + POIs) for a given route polyline [waypoints].
  /// Returns a FlightInfo object. On error, returns an empty FlightInfo.
  Future<FlightInfo> call({
    required String airportDeparture,
    required String airportArrival,
    required List<LatLng> waypoints,
  }) async {
    return await _getPoiApi.getFlightOverview(
      airportDeparture,
      airportArrival,
      waypoints,
    );
  }
}
