import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class FlightPreviewErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const FlightPreviewErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: ErrorStateView(
        title: 'Something went wrong',
        message: message,
        onRetry: onRetry,
        retryLabel: 'Try Again',
      ),
    );
  }
}
