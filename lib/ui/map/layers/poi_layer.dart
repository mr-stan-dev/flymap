import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flymap/entity/flight_poi.dart';
import 'package:flymap/ui/map/layers/map_layer.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class PoiLayer extends MapLayer {
  late final List<FlightPoi> poi;

  PoiLayer({required this.poi});

  static const String _sourceId = 'poi-source';
  static const String _iconsLayerId = 'poi-icons-layer';
  static const String _labelsLayerId = 'poi-labels-layer';

  @override
  void add(MapLibreMapController controller) async {
    // Try to add a runtime image for a universal marker; ignore failures and rely on sprite fallback
    try {
      final bytes = await rootBundle.load('assets/icons/poi_generic.png');
      await controller.addImage('poi-generic', bytes.buffer.asUint8List());
    } catch (_) {}

    // Build a GeoJSON FeatureCollection for points
    final features = poi.map(
      (p) => {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [p.coordinates.longitude, p.coordinates.latitude],
        },
        'properties': {'name': p.name},
      },
    );
    final geojson = {
      'type': 'FeatureCollection',
      'features': features.toList(),
    };

    // Clean up existing
    for (final id in [_labelsLayerId, _iconsLayerId]) {
      try {
        await controller.removeLayer(id);
      } catch (_) {}
    }
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {}

    // Add source
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: geojson),
    );

    // Add icon layer (always visible). Prefer runtime image, fallback to common sprite icons
    await controller.addLayer(
      _sourceId,
      _iconsLayerId,
      SymbolLayerProperties(
        iconImage: [
          'coalesce',
          ['image', 'poi-generic'],
          ['image', 'marker_11'],
          ['image', 'circle_11'],
          ['image', 'dot_11'],
        ],
        iconSize: 2.0,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );

    // Add labels layer (visible from zoom 8+ via opacity expression)
    await controller.addLayer(
      _sourceId,
      _labelsLayerId,
      SymbolLayerProperties(
        textField: ['get', 'name'],
        textSize: [
          'case',
          [
            '<',
            ['zoom'],
            8,
          ],
          0.01,
          12.0,
        ],
        textColor: Colors.white.toHexStringRGB(),
        textHaloColor: AppColoursCommon.accentBlue.toHexStringRGB(),
        textHaloWidth: 3.0,
        textHaloBlur: 0.5,
        textOffset: [0, 1.5],
        textAllowOverlap: true,
        textIgnorePlacement: true,
        textFont: ['Noto Sans Regular'],
      ),
    );
  }
}
