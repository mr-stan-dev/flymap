import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class Airport extends Equatable {
  final String name;
  final String city;
  final String countryCode;
  final LatLng latLon;
  final String iataCode;
  final String icaoCode;
  final String wikipediaUrl;

  const Airport({
    required this.name,
    required this.city,
    required this.countryCode,
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
  String get fullName => '$name ($displayCode)';

  /// Airport name without the trailing word "Airport"
  String get nameShort {
    final cleaned = name
        .replaceAll(RegExp(r'\bInternational\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bAirport\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    return cleaned.isEmpty ? name : cleaned;
  }

  /// Get the city with airport code
  String get cityWithCode => '$city ($displayCode)';

  /// Get the city with country code
  String get cityWithCountryCode => '$city, $countryCode';

  @override
  List<Object?> get props => [
    name,
    city,
    countryCode,
    latLon,
    iataCode,
    icaoCode,
    wikipediaUrl,
  ];
}
