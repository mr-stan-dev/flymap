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

  @override
  List<Object?> get props => [layer, sizeBytes, downloadedAt, filePath];
}
