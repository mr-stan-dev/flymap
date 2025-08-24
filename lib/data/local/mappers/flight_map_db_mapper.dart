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
