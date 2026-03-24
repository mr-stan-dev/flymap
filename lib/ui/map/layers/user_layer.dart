import 'package:maplibre_gl/maplibre_gl.dart';

class UserLayer {
  static CircleOptions markerCircle(LatLng userPosition) {
    return CircleOptions(
      geometry: userPosition,
      circleColor: '#2E7DFF',
      circleRadius: 6.0,
      circleOpacity: 0.9,
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 2.0,
    );
  }

  static SymbolOptions headingArrow(LatLng userPosition, double headingDeg) {
    return SymbolOptions(
      geometry: userPosition,
      textField: '▲',
      textSize: 14.0,
      textColor: '#FFFFFF',
      textHaloColor: '#2E7DFF',
      textHaloWidth: 2.0,
      textRotate: _normalizeHeading(headingDeg),
      textAnchor: 'center',
    );
  }

  static double _normalizeHeading(double headingDeg) {
    final normalized = headingDeg % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}
