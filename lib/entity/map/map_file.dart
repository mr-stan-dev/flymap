import 'package:equatable/equatable.dart';
import 'map_layer.dart';

class MapFile extends Equatable {
  final MapLayer layer;
  final String filePath;

  const MapFile({required this.layer, required this.filePath});

  Map<String, dynamic> toMap() {
    return {'layer': layer.name, 'filePath': filePath};
  }

  factory MapFile.fromMap(Map<String, dynamic> map) {
    return MapFile(
      layer: MapLayer.values.firstWhere(
        (layer) => layer.name == map['layer'],
        orElse: () => MapLayer.outdoors,
      ),
      filePath: map['filePath'] as String,
    );
  }

  @override
  List<Object?> get props => [layer, filePath];
}
