import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

extension LatLonListExt on List<ll.LatLng> {
  List<LatLng> toGeometry() {
    return map((point) => point.toMapLatLon()).toList();
  }
}

extension LatLonExt on ll.LatLng {
  LatLng toMapLatLon() => LatLng(latitude, longitude);
}
