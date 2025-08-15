import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/layers/map_layer.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

class WaypointsLayer extends MapLayer {
  late LineOptions lineOptions;

  WaypointsLayer(List<ll.LatLng> waypoints) {
    lineOptions =  LineOptions(
      lineJoin: 'round',
      geometry: waypoints.toGeometry(),
      lineColor: AppColoursCommon.accentBlue.toHexStringRGB(),
      lineWidth: 2.0,
      lineOpacity: 0.5,
    );
  }

  @override
  void add(MapLibreMapController controller) {
    controller.addLine(lineOptions);
  }
}
