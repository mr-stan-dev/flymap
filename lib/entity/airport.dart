import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Airport entity representing an airport with its details
class Airport extends Equatable {
  final String code;
  final String name;
  final String city;
  final String country;
  final LatLng latLon;
  final String? iataCode;
  final String? icaoCode;

  const Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
    required this.latLon,
    this.iataCode,
    this.icaoCode,
  });

  /// Create an airport from JSON data
  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      code: json['code'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      latLon: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      iataCode: json['iata_code'] as String?,
      icaoCode: json['icao_code'] as String?,
    );
  }

  /// Convert airport to JSON data
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'city': city,
      'country': country,
      'lat': latLon.latitude,
      'lng': latLon.longitude,
      'iata_code': iataCode,
      'icao_code': icaoCode,
    };
  }

  /// Create a copy of this airport with updated fields
  Airport copyWith({
    String? code,
    String? name,
    String? city,
    String? country,
    LatLng? latLon,
    String? iataCode,
    String? icaoCode,
  }) {
    return Airport(
      code: code ?? this.code,
      name: name ?? this.name,
      city: city ?? this.city,
      country: country ?? this.country,
      latLon: latLon ?? this.latLon,
      iataCode: iataCode ?? this.iataCode,
      icaoCode: icaoCode ?? this.icaoCode,
    );
  }

  /// Get the full airport name with code
  String get fullName => '$name ($code)';

  /// Get the city with airport code
  String get cityWithCode => '$city ($code)';

  // Backward compatibility getters
  String get airportName => name;
  String get countryCode => country;

  @override
  List<Object?> get props => [
    code,
    name,
    city,
    country,
    latLon,
    iataCode,
    icaoCode,
  ];

  @override
  String toString() {
    return 'Airport(code: $code, name: $name, city: $city, country: $country, latLon: $latLon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Airport &&
        other.code == code &&
        other.name == name &&
        other.city == city &&
        other.country == country &&
        other.latLon == latLon;
  }

  @override
  int get hashCode {
    return code.hashCode ^
        name.hashCode ^
        city.hashCode ^
        country.hashCode ^
        latLon.hashCode;
  }
}

/// Extension for creating sample airports
extension AirportSamples on Airport {
  /// London Heathrow Airport
  static Airport get londonHeathrow => const Airport(
    code: 'LHR',
    name: 'London Heathrow Airport',
    latLon: LatLng(51.4700, -0.4619),
    city: 'London',
    country: 'GB',
  );

  /// Paris Charles de Gaulle Airport
  static Airport get parisCharlesDeGaulle => const Airport(
    code: 'CDG',
    name: 'Paris Charles de Gaulle Airport',
    latLon: LatLng(49.0097, 2.5499),
    city: 'Paris',
    country: 'FR',
  );

  /// John F. Kennedy International Airport
  static Airport get newYorkJFK => const Airport(
    code: 'JFK',
    name: 'John F. Kennedy International Airport',
    latLon: LatLng(40.6413, -73.7781),
    city: 'New York',
    country: 'US',
  );

  /// O'Hare International Airport
  static Airport get chicagoOHare => const Airport(
    code: 'ORD',
    name: 'O\'Hare International Airport',
    latLon: LatLng(41.9786, -87.9048),
    city: 'Chicago',
    country: 'US',
  );

  /// Amsterdam Airport Schiphol
  static Airport get amsterdamSchiphol => const Airport(
    code: 'AMS',
    name: 'Amsterdam Airport Schiphol',
    latLon: LatLng(52.3105, 4.7639),
    city: 'Amsterdam',
    country: 'NL',
  );

  /// Leonardo da Vinci International Airport
  static Airport get romeFiumicino => const Airport(
    code: 'FCO',
    name: 'Leonardo da Vinci International Airport',
    latLon: LatLng(41.8045, 12.2508),
    city: 'Rome',
    country: 'IT',
  );

  /// Narita International Airport
  static Airport get tokyoNarita => const Airport(
    code: 'NRT',
    name: 'Narita International Airport',
    latLon: LatLng(35.6762, 139.6503),
    city: 'Tokyo',
    country: 'JP',
  );

  /// Los Angeles International Airport
  static Airport get losAngelesLAX => const Airport(
    code: 'LAX',
    name: 'Los Angeles International Airport',
    latLon: LatLng(33.9416, -118.4085),
    city: 'Los Angeles',
    country: 'US',
  );

  /// Frankfurt Airport
  static Airport get frankfurt => const Airport(
    code: 'FRA',
    name: 'Frankfurt Airport',
    latLon: LatLng(50.0379, 8.5706),
    city: 'Frankfurt',
    country: 'DE',
  );

  /// Madrid Barajas Airport
  static Airport get madridBarajas => const Airport(
    code: 'MAD',
    name: 'Madrid Barajas Airport',
    latLon: LatLng(40.4983, -3.5668),
    city: 'Madrid',
    country: 'ES',
  );

  /// Get all sample airports
  static List<Airport> get samples => [
    londonHeathrow,
    parisCharlesDeGaulle,
    newYorkJFK,
    chicagoOHare,
    amsterdamSchiphol,
    romeFiumicino,
    tokyoNarita,
    losAngelesLAX,
    frankfurt,
    madridBarajas,
  ];
}
