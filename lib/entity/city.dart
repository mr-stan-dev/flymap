import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class City extends Equatable {
  final String name;
  final String asciiName;
  final String countryCode;
  final int population;
  final int? elevation; // Can be null or empty in CSV
  final String timezone;
  final LatLng latLon;

  const City({
    required this.name,
    required this.asciiName,
    required this.countryCode,
    required this.population,
    this.elevation,
    required this.timezone,
    required this.latLon,
  });

  @override
  List<Object?> get props => [
        name,
        asciiName,
        countryCode,
        population,
        elevation,
        timezone,
        latLon,
      ];
}
