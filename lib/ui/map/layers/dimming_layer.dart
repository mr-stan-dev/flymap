import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/layers/map_layer.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

class DimmingLayer extends MapLayer {
  late FillOptions fillOptions;

  DimmingLayer(List<ll.LatLng> corridor) {
    fillOptions = FillOptions(
      geometry: [
        [
          LatLng(-89.9, -179.9), // Southwest corner
          LatLng(-89.9, 179.9), // Southeast corner
          LatLng(89.9, 179.9), // Northeast corner
          LatLng(89.9, -179.9), // Northwest corner
          LatLng(-89.9, -179.9), // Close the polygon
        ],
        corridor.toGeometry(),
      ],
      fillColor: "#808080",
      fillOpacity: 0.3,
    );
  }

  @override
  void add(MapLibreMapController controller) {
    controller.addFill(fillOptions);
  }
}
