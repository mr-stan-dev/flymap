import 'package:flymap/data/api/flight_info_api.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:latlong2/latlong.dart';

/// Use case to fetch flight-related info (e.g., POIs) via backend Cloud Function
class GetFlightInfoUseCase {
  final FlightInfoApi _flightInfoApi;

  GetFlightInfoUseCase({required FlightInfoApi flightInfoApi})
    : _flightInfoApi = flightInfoApi;

  Future<FlightInfo> call({
    required String airportDeparture,
    required String airportArrival,
    required List<LatLng> waypoints,
  }) async {
    return await _flightInfoApi.getFlightOverview(
      airportDeparture,
      airportArrival,
      waypoints,
    );
  }
}
