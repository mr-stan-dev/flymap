import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';

class FlightDownloading extends StatelessWidget {
  final FlightPreviewAirports airports;
  final MapDownloadingState downloadingState;

  const FlightDownloading({
    super.key,
    required this.airports,
    required this.downloadingState,
  });

  @override
  Widget build(BuildContext context) {
    final downloadPercentage = (downloadingState.progress * 100).toInt();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Download icon with animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.download, size: 60, color: primary),
          ),
          const SizedBox(height: 32),

          Text(
            'Downloading Flight Map',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloading map tiles for offline use',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Flight info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${airports.departure.displayCode}-${airports.arrival.displayCode}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${airports.departure.city} → ${airports.arrival.city}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Single progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.download, color: primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Downloading progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$downloadPercentage%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: downloadingState.progress,
                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cancel button
          TextButton(
            onPressed: () {
              context.read<FlightPreviewCubit>().cancelDownload();
            },
            child: const Text(
              'Cancel Download',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
