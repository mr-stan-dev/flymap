import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/domain/entity/flight_poi_type.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/layers/map_layer.dart';
import 'package:flymap/ui/map/layers/poi_style_config.dart';
import 'package:flymap/ui/screens/shared/poi_type_marker_asset.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class PoiLayer extends MapLayer {
  final List<RoutePoiSummary> poi;
  final Logger _logger = const Logger('PoiLayer');

  PoiLayer({required this.poi});

  static const String sourceId = 'poi-source';
  static const String clusterCirclesLayerId = 'poi-cluster-circles-layer';
  static const String clusterCountsLayerId = 'poi-cluster-counts-layer';
  static const String circlesLayerId = 'poi-circles-layer';
  static const String iconsLayerId = 'poi-icons-layer';
  static const String labelsLayerId = 'poi-labels-layer';
  static final List<PoiLegendEntry> legendEntries = PoiStyleConfig.legendOrder
      .map(
        (type) =>
            PoiLegendEntry(type: type, color: PoiStyleConfig.colorFor(type)),
      )
      .toList(growable: false);
  static Color get defaultColor =>
      PoiStyleConfig.colorFor(FlightPoiType.unknown);
  static final Map<String, Uint8List> _iconBytesCache = {};

  @override
  Future<void> add(MapLibreMapController controller) async {
    final iconTypes = await _ensurePoiIconsRegistered(controller);

    final typeCounts = <String, int>{};
    for (final item in poi) {
      typeCounts.update(item.type.rawValue, (v) => v + 1, ifAbsent: () => 1);
    }
    _logger.log('Rendering POIs count=${poi.length} typeCounts=$typeCounts');

    // Build a GeoJSON FeatureCollection for points. The incoming list is
    // importance-ordered (backend popularity rank preserved by the tier
    // selection), so the index doubles as a collision priority: lower rank
    // wins when symbols compete for space.
    final features = poi.indexed.map((entry) {
      final (index, p) = entry;
      final hasIcon = iconTypes.contains(p.type);
      return {
        'id': p.qid.trim().isNotEmpty ? p.qid : p.name,
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [p.latLon.longitude, p.latLon.latitude],
        },
        'properties': {
          'name': p.name,
          'type': p.type.rawValue,
          'icon_id': _iconIdForType(p.type),
          'has_icon': hasIcon,
          'qid': p.qid,
          'sitelinks': p.sitelinks,
          'route_progress': p.routeProgress,
          'rank': index,
        },
      };
    });
    final geojson = {
      'type': 'FeatureCollection',
      'features': features.toList(),
    };
    _logger.log('GeoJSON features=${features.length}');

    // Clean up existing
    for (final id in [
      labelsLayerId,
      iconsLayerId,
      circlesLayerId,
      clusterCountsLayerId,
      clusterCirclesLayerId,
    ]) {
      try {
        await controller.removeLayer(id);
      } catch (_) {}
    }
    try {
      await controller.removeSource(sourceId);
    } catch (_) {}

    // Add source
    await controller.addSource(
      sourceId,
      GeojsonSourceProperties(data: geojson, cluster: false),
    );

    // Add circles with type-based colors for lower zoom levels.
    await controller.addLayer(
      sourceId,
      circlesLayerId,
      CircleLayerProperties(
        circleRadius: [
          'step',
          ['zoom'],
          2.8,
          6,
          3.6,
          9,
          5.5,
        ],
        circleColor: _buildTypeColorExpression(),
        circleStrokeWidth: 1.2,
        circleStrokeColor: Colors.white.toHexStringRGB(),
        // iOS requires ["zoom"] to be used only as input to top-level
        // "step"/"interpolate" expressions.
        circleOpacity: _circleOpacityExpression(),
        // Must mirror the fill: a hidden or dimmed fill with a full-strength
        // white stroke reads as a stray white ring.
        circleStrokeOpacity: _circleOpacityExpression(),
      ),
    );

    // Icon + label as ONE symbol per place (icons visible from zoom 7+,
    // labels from 8+ via size expressions). Keeping them in a single layer
    // is what makes collision behave: a symbol never collides with its own
    // text, and textOptional drops the label while keeping the icon when
    // space is tight. The sort key makes the more important place win.
    await controller.addLayer(
      sourceId,
      iconsLayerId,
      SymbolLayerProperties(
        iconImage: ['get', 'icon_id'],
        iconSize: [
          'step',
          ['zoom'],
          0.0,
          7,
          0.208,
          9,
          0.272,
          12,
          0.42,
        ],
        iconAllowOverlap: false,
        iconIgnorePlacement: false,
        textField: ['get', 'name'],
        textSize: [
          'step',
          ['zoom'],
          0.0,
          8,
          12.0,
        ],
        textColor: _buildTypeTextColorExpression(),
        textHaloColor: PoiStyleConfig.textHaloColor.toHexStringRGB(),
        textHaloWidth: 3.0,
        textHaloBlur: 0.5,
        textOffset: [0, 1.5],
        textAllowOverlap: false,
        textIgnorePlacement: false,
        textOptional: true,
        textFont: ['Noto Sans Regular'],
        symbolSortKey: ['get', 'rank'],
      ),
      filter: [
        '==',
        ['get', 'has_icon'],
        true,
      ],
    );

    // Label-only layer for the rare POI types without a registered icon
    // (their circle stays visible at all zooms).
    await controller.addLayer(
      sourceId,
      labelsLayerId,
      SymbolLayerProperties(
        textField: ['get', 'name'],
        textSize: [
          'step',
          ['zoom'],
          0.0,
          8,
          12.0,
        ],
        textColor: _buildTypeTextColorExpression(),
        textHaloColor: PoiStyleConfig.textHaloColor.toHexStringRGB(),
        textHaloWidth: 3.0,
        textHaloBlur: 0.5,
        textOffset: [0, 1.5],
        textAllowOverlap: false,
        textIgnorePlacement: false,
        symbolSortKey: ['get', 'rank'],
        textFont: ['Noto Sans Regular'],
      ),
      filter: [
        '==',
        ['get', 'has_icon'],
        false,
      ],
    );
  }

  /// Shared by fill and stroke. At cruise zooms the long tail (rank >= 40)
  /// renders as a faint texture so top places read clearly. Circles stay
  /// visible at ALL zooms: they are the guaranteed baseline for every place,
  /// so a POI whose icon loses the collision contest degrades to its dot
  /// instead of disappearing (winning icons simply draw on top).
  List<dynamic> _circleOpacityExpression() {
    return <dynamic>[
      'step',
      ['zoom'],
      [
        'case',
        [
          '<',
          ['get', 'rank'],
          40,
        ],
        0.95,
        0.4,
      ],
      6,
      0.95,
    ];
  }

  List<dynamic> _buildTypeColorExpression() {
    final expression = <dynamic>[
      'match',
      ['get', 'type'],
    ];
    for (final entry in legendEntries) {
      expression
        ..add(entry.type.rawValue)
        ..add(entry.color.toHexStringRGB());
    }
    expression.add(defaultColor.toHexStringRGB());
    return expression;
  }

  List<dynamic> _buildTypeTextColorExpression() {
    return _buildTypeColorExpression();
  }

  Future<Set<FlightPoiType>> _ensurePoiIconsRegistered(
    MapLibreMapController controller,
  ) async {
    final availableTypes = <FlightPoiType>{};
    var added = 0;
    var alreadyAdded = 0;
    var missing = 0;
    var failed = 0;
    for (final type in FlightPoiType.values) {
      final imageName = _iconIdForType(type);
      final assetPath = PoiTypeMarkerAsset.iconPathFor(type);
      final bytes = await _loadIconBytes(assetPath);
      if (bytes == null) {
        missing++;
        continue;
      }
      try {
        await controller.addImage(imageName, bytes);
        added++;
        availableTypes.add(type);
      } catch (e) {
        if (_isImageAlreadyRegisteredError(e)) {
          alreadyAdded++;
          // Already present in style image cache, icon is still usable.
          availableTypes.add(type);
        } else {
          failed++;
          _logger.error(
            'Failed to register POI icon "$imageName" from "$assetPath": $e',
          );
        }
      }
    }
    _logger.log(
      'POI icons registered available=${availableTypes.length} '
      'added=$added alreadyAdded=$alreadyAdded missing=$missing failed=$failed',
    );
    return availableTypes;
  }

  Future<Uint8List?> _loadIconBytes(String assetPath) async {
    final cached = _iconBytesCache[assetPath];
    if (cached != null) return cached;
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      _iconBytesCache[assetPath] = bytes;
      return bytes;
    } catch (e) {
      _logger.error('POI icon asset not available at "$assetPath": $e');
      return null;
    }
  }

  String _iconIdForType(FlightPoiType type) {
    return 'poi-icon-${type.rawValue}';
  }

  bool _isImageAlreadyRegisteredError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('already exists') ||
        text.contains('image already added') ||
        text.contains('image with name');
  }
}

class PoiLegendEntry {
  const PoiLegendEntry({required this.type, required this.color});

  final FlightPoiType type;
  final Color color;
}
