import 'package:equatable/equatable.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:latlong2/latlong.dart';

class RoutePoi extends Equatable {
  const RoutePoi({
    required this.qid,
    required this.name,
    required this.latLon,
    required this.type,
    required this.sitelinks,
  });

  final String qid;
  final String name;
  final LatLng latLon;
  final FlightPoiType type;
  final int sitelinks;

  @override
  List<Object?> get props => [qid, name, latLon, type, sitelinks];
}
