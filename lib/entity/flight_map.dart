import 'package:equatable/equatable.dart';

class FlightMap extends Equatable {
  final String layer;
  final int sizeBytes;
  final DateTime downloadedAt;
  final String filePath;

  const FlightMap({
    required this.layer,
    required this.sizeBytes,
    required this.downloadedAt,
    required this.filePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'layer': layer,
      'sizeBytes': sizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
      'filePath': filePath,
    };
  }

  factory FlightMap.fromMap(Map<String, dynamic> map) {
    final String resolvedLayer = map['layer'] as String;

    String? resolvedFilePath = map['filePath'] as String?;
    if (resolvedFilePath == null) {
      final dynamic files = map['mapFiles'];
      if (files is List && files.isNotEmpty) {
        final first = files.first;
        if (first is Map<String, dynamic>) {
          resolvedFilePath = first['filePath'] as String?;
        }
      }
    }

    return FlightMap(
      layer: resolvedLayer,
      sizeBytes: (map['sizeBytes'] as num).toInt(),
      downloadedAt: DateTime.parse(map['downloadedAt'] as String),
      filePath: resolvedFilePath ?? '',
    );
  }

  @override
  List<Object?> get props => [layer, sizeBytes, downloadedAt, filePath];
}
