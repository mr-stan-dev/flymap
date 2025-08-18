import 'package:latlong2/latlong.dart';
import 'package:flymap/data/api/get_poi_api.dart';
import 'package:flymap/entity/flight_poi.dart';

/// Use case to fetch flight-related info (e.g., POIs) via backend Cloud Function
class GetFlightInfoUseCase {
  final GetPoiApi _getPoiApi;

  GetFlightInfoUseCase({required GetPoiApi getPoiApi}) : _getPoiApi = getPoiApi;

  /// Fetch Points of Interest for a given route polyline [coordinates].
  /// Returns a list of FlightPoi. On error, returns empty list.
  Future<List<FlightPoi>> call({required List<LatLng> coordinates}) async {
    try {
      final result = await _getPoiApi.getPoiCallable(coordinates);
      result.forEach((key, value) {
        print('key: $key, value: $value');
      });
      final dynamic list = result['poi'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .map(FlightPoi.fromMap)
            .toList();
      }
      return const <FlightPoi>[];
    } catch (_) {
      return const <FlightPoi>[];
    }
  }
}
