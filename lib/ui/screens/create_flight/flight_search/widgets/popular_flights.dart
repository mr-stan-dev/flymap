import 'package:flymap/entity/airport.dart';
import 'package:latlong2/latlong.dart';

const popularFlights = [
  {
    'departure': Airport(
      code: 'LTN',
      name: 'London Luton Airport',
      latLon: const LatLng(51.8747, -0.3683),
      city: 'London',
      country: 'GB',
    ),
    'arrival': Airport(
      code: 'BER',
      name: 'Berlin Brandenburg Airport',
      latLon: const LatLng(52.3667, 13.5033),
      city: 'Berlin',
      country: 'DE',
    ),
  },
  {
    'departure': Airport(
      code: 'CDG',
      name: 'Charles de Gaulle Airport',
      latLon: const LatLng(49.0097, 2.5479),
      city: 'Paris',
      country: 'FR',
    ),
    'arrival': Airport(
      code: 'FCO',
      name: 'Leonardo da Vinci International Airport',
      latLon: const LatLng(41.8045, 12.2508),
      city: 'Rome',
      country: 'IT',
    ),
  },
  {
    'departure': Airport(
      code: 'AMS',
      name: 'Amsterdam Airport Schiphol',
      latLon: const LatLng(52.3086, 4.7639),
      city: 'Amsterdam',
      country: 'NL',
    ),
    'arrival': Airport(
      code: 'MAD',
      name: 'Adolfo Suárez Madrid–Barajas Airport',
      latLon: const LatLng(40.4983, -3.5676),
      city: 'Madrid',
      country: 'ES',
    ),
  },
  // USA flights
  {
    'departure': Airport(
      code: 'LAX',
      name: 'Los Angeles International Airport',
      latLon: const LatLng(33.9416, -118.4085),
      city: 'Los Angeles',
      country: 'US',
    ),
    'arrival': Airport(
      code: 'SFO',
      name: 'San Francisco International Airport',
      latLon: const LatLng(37.6213, -122.3790),
      city: 'San Francisco',
      country: 'US',
    ),
  },
  {
    'departure': Airport(
      code: 'JFK',
      name: 'John F. Kennedy International Airport',
      latLon: const LatLng(40.6413, -73.7781),
      city: 'New York',
      country: 'US',
    ),
    'arrival': Airport(
      code: 'MIA',
      name: 'Miami International Airport',
      latLon: const LatLng(25.7959, -80.2870),
      city: 'Miami',
      country: 'US',
    ),
  },
];
