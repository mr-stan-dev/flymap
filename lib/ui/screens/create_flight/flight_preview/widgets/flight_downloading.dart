import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ProgressStateView(
          title: context.t.preview.downloadingMapTitle,
          subtitle:
              '${airports.departure.displayCode} -> ${airports.arrival.displayCode}',
          progress: downloadingState.progress,
          leadingIcon: Icons.download_rounded,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xl),
          child: SecondaryButton(
            label: context.t.preview.cancelDownload,
            onPressed: () =>
                context.read<FlightPreviewCubit>().cancelDownload(),
            leadingIcon: Icons.close_rounded,
          ),
        ),
        const SizedBox(height: DsSpacing.lg),
      ],
    );
  }
}
