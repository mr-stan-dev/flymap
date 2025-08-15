import 'package:equatable/equatable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

sealed class MapPoi extends Equatable {
  final LatLng latLng;
  const MapPoi(this.latLng);

  @override
  List<Object?> get props => [latLng];
}

class GeneralPoi extends MapPoi {
  const GeneralPoi(super.latLng);
}