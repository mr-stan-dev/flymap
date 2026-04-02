import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';

class MapStyleLoadingView extends StatelessWidget {
  const MapStyleLoadingView({super.key, this.message, this.isError = false});

  final String? message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final resolvedMessage = message ?? context.t.flight.map.loadingStyle;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isError)
            Icon(Icons.error_outline_rounded, color: color.error, size: 30)
          else
            const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              resolvedMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: isError ? color.error : null),
            ),
          ),
        ],
      ),
    );
  }
}
