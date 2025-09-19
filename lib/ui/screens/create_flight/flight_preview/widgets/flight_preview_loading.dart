import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';

class FlightPreviewLoadingWidget extends StatelessWidget {
  final FlightPreviewAirports airports;

  const FlightPreviewLoadingWidget({super.key, required this.airports});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Calculating flight route...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '${airports.departure.displayCode} → ${airports.arrival.displayCode}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
