import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/ui/map/layers/map_layer.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class AirportsLayer extends MapLayer {
  static const String _sourceId = 'airports-source';
  static const String _pinsLayerId = 'airports-pins-layer';
  static const String _labelsLayerId = 'airports-labels-layer';

  final Airport departure;
  final Airport arrival;

  AirportsLayer({required this.departure, required this.arrival});

  @override
  Future<void> add(MapLibreMapController controller) async {
    // Remove existing airport layers/source if this is a refresh.
    for (final id in [_labelsLayerId, _pinsLayerId]) {
      try {
        await controller.removeLayer(id);
      } catch (_) {}
    }
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {}

    final geojson = _toGeoJson([departure, arrival]);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: geojson),
    );

    // Render airport pin as a circle for guaranteed tint + contrast.
    await controller.addLayer(
      _sourceId,
      _pinsLayerId,
      CircleLayerProperties(
        circleColor: AppColoursCommon.brandTeal.toHexStringRGB(),
        circleRadius: 6.0,
        circleOpacity: 0.95,
        circleStrokeColor: Colors.white.toHexStringRGB(),
        circleStrokeWidth: 2.0,
      ),
    );

    // Airport code labels render in a dedicated symbol layer to keep them
    // stable at low zooms and independent from annotation manager state.
    await controller.addLayer(
      _sourceId,
      _labelsLayerId,
      SymbolLayerProperties(
        textField: ['get', 'code'],
        textSize: 12.0,
        textAllowOverlap: true,
        textIgnorePlacement: true,
        textOptional: true,
        textAnchor: 'bottom',
        textOffset: [0, -1.35],
        textColor: Colors.white.toHexStringRGB(),
        textHaloColor: AppColoursCommon.brandTeal.toHexStringRGB(),
        textHaloWidth: 1.8,
        textFont: ['Noto Sans Bold'],
      ),
    );
  }

  Map<String, dynamic> _toGeoJson(List<Airport> airports) => {
    'type': 'FeatureCollection',
    'features': airports
        .map(
          (airport) => {
            'type': 'Feature',
            'geometry': <String, dynamic>{
              'type': 'Point',
              'coordinates': [
                airport.latLon.longitude,
                airport.latLon.latitude,
              ],
            },
            'properties': <String, dynamic>{
              'code': airport.displayCode,
            },
          },
        )
        .toList(),
  };
}
