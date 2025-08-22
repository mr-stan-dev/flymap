import 'package:flymap/entity/airport.dart';
import 'package:latlong2/latlong.dart';

const popularFlights = [
  {
    'departure': Airport(
      name: 'London Luton Airport',
      latLon: const LatLng(51.8747, -0.3683),
      city: 'London',
      country: 'GB',
      iataCode: 'LTN',
      icaoCode: '',
      wikipediaUrl: '',
    ),
    'arrival': Airport(
      name: 'Berlin Brandenburg Airport',
      latLon: const LatLng(52.3667, 13.5033),
      city: 'Berlin',
      country: 'DE',
      iataCode: 'BER',
      icaoCode: '',
      wikipediaUrl: '',
    ),
  },
  {
    'departure': Airport(
      name: 'Charles de Gaulle Airport',
      latLon: const LatLng(49.0097, 2.5479),
      city: 'Paris',
      country: 'FR',
      iataCode: 'CDG',
      icaoCode: '',
      wikipediaUrl: '',
    ),
    'arrival': Airport(
      name: 'Leonardo da Vinci International Airport',
      latLon: const LatLng(41.8045, 12.2508),
      city: 'Rome',
      country: 'IT',
      iataCode: 'FCO',
      icaoCode: '',
      wikipediaUrl: '',
    ),
  },
  {
    'departure': Airport(
      name: 'Amsterdam Airport Schiphol',
      latLon: const LatLng(52.3086, 4.7639),
      city: 'Amsterdam',
      country: 'NL',
      iataCode: 'AMS',
      icaoCode: '',
      wikipediaUrl: '',
    ),
    'arrival': Airport(
      name: 'Adolfo Suárez Madrid–Barajas Airport',
      latLon: const LatLng(40.4983, -3.5676),
      city: 'Madrid',
      country: 'ES',
      iataCode: 'MAD',
      icaoCode: '',
      wikipediaUrl: '',
    ),
  },
  // USA flights
  {
    'departure': Airport(
      name: 'Los Angeles International Airport',
      latLon: const LatLng(33.9416, -118.4085),
      city: 'Los Angeles',
      country: 'US',
      iataCode: 'LAX',
      icaoCode: '',
      wikipediaUrl: '',
    ),
    'arrival': Airport(
      name: 'San Francisco International Airport',
      latLon: const LatLng(37.6213, -122.3790),
      city: 'San Francisco',
      country: 'US',
      iataCode: 'SFO',
      icaoCode: '',
      wikipediaUrl: '',
    ),
  },
  {
    'departure': Airport(
      name: 'John F. Kennedy International Airport',
      latLon: const LatLng(40.6413, -73.7781),
      city: 'New York',
      country: 'US',
      iataCode: 'JFK',
      icaoCode: '',
      wikipediaUrl: '',
    ),
    'arrival': Airport(
      name: 'Miami International Airport',
      latLon: const LatLng(25.7959, -80.2870),
      city: 'Miami',
      country: 'US',
      iataCode: 'MIA',
      icaoCode: '',
      wikipediaUrl: '',
    ),
  },
];
