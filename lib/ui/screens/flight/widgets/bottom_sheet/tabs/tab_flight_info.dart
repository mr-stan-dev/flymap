import 'package:flymap/entity/airport.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_info.dart';
import 'package:flutter/material.dart';

class TabFlightInfo extends StatelessWidget {
  const TabFlightInfo({
    required this.departure,
    required this.arrival,
    super.key,
  });

  final Airport departure;
  final Airport arrival;

  @override
  Widget build(BuildContext context) {
    return FlightInfo(
      airports: FlightPreviewAirports(
        departure: departure,
        arrival: arrival,
      ),
    );
  }
}
