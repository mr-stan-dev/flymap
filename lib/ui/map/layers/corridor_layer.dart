import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/layers/map_layer.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

class CorridorLayer extends MapLayer {
  late LineOptions lineOptions;

  CorridorLayer(List<ll.LatLng> corridor) {
    lineOptions = LineOptions(
      lineJoin: 'round',
      geometry: corridor.toGeometry(),
      lineColor: AppColoursCommon.accentBlue.toHexStringRGB(),
      lineWidth: 3.0,
      lineOpacity: 0.7,
    );
  }

  @override
  void add(MapLibreMapController controller) {
    controller.addLine(lineOptions);
  }
}
