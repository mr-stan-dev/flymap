import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class FlightDownloadCompletion extends StatelessWidget {
  const FlightDownloadCompletion({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuccessStateView(
      title: 'Download Complete!',
      subtitle: 'Flight has been saved',
      footer: 'Navigating to home...',
    );
  }
}
