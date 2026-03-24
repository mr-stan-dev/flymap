import 'package:flutter/material.dart';

class MapInitializingOverlay extends StatelessWidget {
  const MapInitializingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing map...'),
            ],
          ),
        ),
      ),
    );
  }
}
