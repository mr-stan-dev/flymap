import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/layers/map_layer.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

class UserLayer {
  late CircleOptions userOptions;

  UserLayer(LatLng userPosition) {
    userOptions = CircleOptions(
      geometry: userPosition,
      circleColor: '#2E7DFF',
      circleRadius: 6.0,
      circleOpacity: 0.9,
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 2.0,
    );
  }
}
