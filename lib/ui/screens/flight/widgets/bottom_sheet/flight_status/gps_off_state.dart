import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';

class GpsOffState extends StatelessWidget {
  const GpsOffState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.gps_off, color: Colors.grey[400], size: 48),
        const SizedBox(height: 12),
        Text(
          'GPS is Turned Off',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please enable location services in your device settings to track your flight progress',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) => ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement open device settings
              // For now, just show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please enable location services in device settings',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
