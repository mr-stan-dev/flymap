import 'package:flymap/data/local/mappers/mapper_utils.dart';
import 'package:flymap/entity/airport.dart';
import 'package:latlong2/latlong.dart';

class AirportDBKeys {
  static const name = 'name';
  static const city = 'city';
  static const country = 'country';
  static const latitude = 'latitude';
  static const longitude = 'longitude';
  static const iata = 'iata';
  static const icao = 'icao';
  static const wiki = 'wiki';
}

class AirportDbMapper {
  Airport fromDb(Map<String, dynamic> map) {
    return Airport(
      name: map.getString(AirportDBKeys.name),
      city: map.getString(AirportDBKeys.city),
      countryCode: map.getString(AirportDBKeys.country, defVal: 'Unknown'),
      latLon: LatLng(
        map.getDouble(AirportDBKeys.latitude),
        map.getDouble(AirportDBKeys.longitude),
      ),
      iataCode: map.getString(AirportDBKeys.iata),
      icaoCode: map.getString(AirportDBKeys.icao),
      wikipediaUrl: map.getString(AirportDBKeys.wiki),
    );
  }

  Map<String, dynamic> toDb(Airport airport) => <String, dynamic>{
    AirportDBKeys.name: airport.name,
    AirportDBKeys.city: airport.city,
    AirportDBKeys.country: airport.countryCode,
    AirportDBKeys.latitude: airport.latLon.latitude,
    AirportDBKeys.longitude: airport.latLon.longitude,
    AirportDBKeys.iata: airport.iataCode,
    AirportDBKeys.icao: airport.icaoCode,
    AirportDBKeys.wiki: airport.wikipediaUrl,
  };
}
