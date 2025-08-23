import 'package:flutter/material.dart';

class FlightDownloadCompletion extends StatelessWidget {
  const FlightDownloadCompletion({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(
            'Download Complete!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Flight has been saved',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Navigating to home...',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
