import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
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
      appBar: AppBar(title: Text(context.t.preview.errorTitle)),
      body: ErrorStateView(
        title: context.t.preview.errorSomethingWrong,
        message: message,
        onRetry: onRetry,
        retryLabel: context.t.preview.tryAgain,
      ),
    );
  }
}
