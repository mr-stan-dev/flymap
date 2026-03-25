import 'package:maplibre_gl/maplibre_gl.dart';

abstract class MapLayer {
  Future<void> add(MapLibreMapController controller);
}
