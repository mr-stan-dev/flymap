import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';

class FlightPreviewLoadingWidget extends StatelessWidget {
  final FlightPreviewAirports airports;

  const FlightPreviewLoadingWidget({super.key, required this.airports});

  @override
  Widget build(BuildContext context) {
    return LoadingStateView(
      title: context.t.preview.calculatingRoute,
      subtitle:
          '${airports.departure.displayCode} -> ${airports.arrival.displayCode}',
    );
  }
}
