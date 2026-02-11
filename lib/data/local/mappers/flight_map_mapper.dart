import 'dart:convert';

import 'package:flymap/entity/flight_map.dart';

class FlightMapDBKeys {
  static const layer = 'layer';
  static const sizeBytes = 'sizeBytes';
  static const downloadedAt = 'downloadedAt';
  static const filePath = 'filePath';
}

class FlightMapDbMapper {
  Map<String, dynamic> toDb(FlightMap fm) => <String, dynamic>{
    FlightMapDBKeys.layer: fm.layer,
    FlightMapDBKeys.sizeBytes: fm.sizeBytes,
    FlightMapDBKeys.downloadedAt: fm.downloadedAt.toIso8601String(),
    FlightMapDBKeys.filePath: fm.filePath,
  };

  FlightMap fromDb(Map<String, dynamic> map) {
    return FlightMap(
      layer: (map[FlightMapDBKeys.layer] ?? '').toString(),
      sizeBytes: (map[FlightMapDBKeys.sizeBytes] as num).toInt(),
      downloadedAt: DateTime.parse(
        (map[FlightMapDBKeys.downloadedAt] ?? '').toString(),
      ),
      filePath: (map[FlightMapDBKeys.filePath] ?? '').toString(),
    );
  }
}

class FlightMapStyleMapper {
  /// Injects an mbtiles URL into the style JSON for the 'openmaptiles' source.
  /// Also updates sprite and glyph paths to point to the current cache directory.
  /// Returns the updated JSON string; if not applicable, returns the original.
  String mapStyleWithMbtiles(
    String styleJson,
    String absoluteMbtilesPath, {
    required String cacheDir,
  }) {
    try {
      final style = jsonDecode(styleJson) as Map<String, dynamic>;
      final sources = style['sources'];
      if (sources is Map && sources['openmaptiles'] is Map) {
        (sources['openmaptiles'] as Map)['url'] =
            'mbtiles://$absoluteMbtilesPath';
      }
      // Fix sprite/glyph paths to point to the current platform cache directory
      style['sprite'] = 'file://$cacheDir/assets/sprites/sprite';
      style['glyphs'] =
          'file://$cacheDir/assets/glyphs/{fontstack}/{range}.pbf';
      return jsonEncode(style);
    } catch (_) {
      return styleJson;
    }
  }
}
