import 'package:maplibre_gl/maplibre_gl.dart';

class UserLayer {
  static CircleOptions markerCircle(
    LatLng userPosition, {
    bool visible = true,
    bool approximate = false,
  }) {
    return CircleOptions(
      geometry: userPosition,
      circleColor: approximate ? '#8490A3' : '#2E7DFF',
      circleRadius: visible ? 6.0 : 0.0,
      circleOpacity: visible ? 0.9 : 0.0,
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: visible ? 2.0 : 0.0,
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

  static SymbolOptions planePin(
    LatLng userPosition,
    double headingDeg, {
    required String imageId,
    bool visible = true,
  }) {
    return SymbolOptions(
      geometry: userPosition,
      iconImage: imageId,
      iconSize: visible ? 0.52 : 0.0,
      iconRotate: _normalizeHeading(headingDeg),
      iconAnchor: 'center',
    );
  }

  static double _normalizeHeading(double headingDeg) {
    final normalized = headingDeg % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}
