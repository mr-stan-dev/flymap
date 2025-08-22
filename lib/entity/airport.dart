import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class Airport extends Equatable {
  final String name;
  final String city;
  final String country;
  final LatLng latLon;
  final String iataCode;
  final String icaoCode;
  final String wikipediaUrl;

  const Airport({
    required this.name,
    required this.city,
    required this.country,
    required this.latLon,
    required this.iataCode,
    required this.icaoCode,
    required this.wikipediaUrl,
  });

  /// Preferred ops/ID code
  String get primaryCode => icaoCode.isNotEmpty ? icaoCode : iataCode;

  /// Display code for UI (IATA if available, else ICAO)
  String get displayCode => iataCode.isNotEmpty ? iataCode : icaoCode;

  /// Get the full airport name with code
  String get fullName => '$name (${displayCode})';

  /// Get the city with airport code
  String get cityWithCode => '$city (${displayCode})';

  // Backward compatibility getters
  String get airportName => name;
  String get countryCode => country;

  @override
  List<Object?> get props => [
    name,
    city,
    country,
    latLon,
    iataCode,
    icaoCode,
    wikipediaUrl,
  ];
}
