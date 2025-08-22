import 'package:flymap/entity/airport.dart';
import 'package:latlong2/latlong.dart';

class AirportDbMapper {
  Airport fromDb(Map<String, dynamic> map) {
    return Airport(
      name: (map['name'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      country: (map['country'] ?? 'Unknown').toString(),
      latLon: LatLng(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      ),
      iataCode: (map['iata'] ?? '').toString(),
      icaoCode: (map['icao'] ?? '').toString(),
      wikipediaUrl: (map['wiki'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toDb(Airport airport) => <String, dynamic>{
    'name': airport.airportName,
    'city': airport.city,
    'country': airport.country,
    'latitude': airport.latLon.latitude,
    'longitude': airport.latLon.longitude,
    'iata': airport.iataCode,
    'icao': airport.icaoCode,
    'wiki': airport.wikipediaUrl,
  };
}
