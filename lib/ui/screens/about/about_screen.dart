import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(title: const Text('About Flymap')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Flymap',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Offline maps for flights. Plan a route between airports and download vector tiles for seamless offline navigation during your flight.',
              style: TextStyle(color: onSurface.withOpacity(0.8)),
            ),
            const SizedBox(height: 24),
            Text(
              'How to use',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Open the + button to create a flight.'),
            const Text('• Pick departure and arrival airports.'),
            const Text('• Preview the route and corridor on the map.'),
            const Text('• Tap Download to save tiles for offline use.'),
            const Text('• Open the flight from Home to view the offline map.'),
          ],
        ),
      ),
    );
  }
}
