import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/info/flight_info_widget.dart';
import 'package:flutter/material.dart';

class TabFlightInfo extends StatelessWidget {
  const TabFlightInfo({
    required this.departure,
    required this.arrival,
    required this.flightInfo,
    super.key,
  });

  final Airport departure;
  final Airport arrival;
  final FlightInfo flightInfo;

  @override
  Widget build(BuildContext context) {
    return FlightInfoWidget(
      airports: FlightPreviewAirports(
        departure: departure,
        arrival: arrival,
      ),
      flightInfo: flightInfo,
    );
  }
}
