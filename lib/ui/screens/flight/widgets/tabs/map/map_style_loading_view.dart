import 'package:flutter/material.dart';

class MapStyleLoadingView extends StatelessWidget {
  const MapStyleLoadingView({
    super.key,
    this.message = 'Loading map style...',
    this.isError = false,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
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
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: isError ? color.error : null),
            ),
          ),
        ],
      ),
    );
  }
}
