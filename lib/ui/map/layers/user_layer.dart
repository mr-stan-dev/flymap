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
