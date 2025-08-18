import 'package:cloud_functions/cloud_functions.dart';
import 'package:latlong2/latlong.dart';

class GetPoiApi {
  final functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> getPoiCallable(List<LatLng> coordinates) async {
    final result = await functions.httpsCallable('get_poi_callable').call(
      <String, dynamic>{
        'coordinates': coordinates
            .map((c) => [c.latitude, c.longitude])
            .toList(),
      },
    );
    return Map<String, dynamic>.from(result.data as Map);
  }
}
