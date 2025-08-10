import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';

class GpsNotGrantedState extends StatelessWidget {
  const GpsNotGrantedState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.location_off, color: Colors.orange[400], size: 48),
        const SizedBox(height: 12),
        Text(
          'Location Permission Required',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This app needs location permission to track your flight progress and provide real-time data',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) => ElevatedButton.icon(
            onPressed: () {
              context.read<FlightScreenCubit>().requestLocationPermission();
            },
            icon: const Icon(Icons.location_on, size: 16),
            label: const Text('Grant Permission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
