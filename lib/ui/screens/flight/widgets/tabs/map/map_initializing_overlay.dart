import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';

class MapInitializingOverlay extends StatelessWidget {
  const MapInitializingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(context.t.flight.map.initializing),
            ],
          ),
        ),
      ),
    );
  }
}
