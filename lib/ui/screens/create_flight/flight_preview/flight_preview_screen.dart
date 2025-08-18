import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_downloading.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_info.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_map_preview.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:get_it/get_it.dart';

class FlightPreviewScreen extends StatelessWidget {
  final FlightPreviewAirports airports;

  const FlightPreviewScreen({super.key, required this.airports});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlightPreviewCubit(
        params: airports,
        downloadMapUseCase: GetIt.I.get(),
        getFlightInfoUseCase: GetIt.I.get(),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Flight preview')),
        body: SafeArea(
          child: BlocConsumer<FlightPreviewCubit, FlightPreviewState>(
            listener: (context, state) {
              // Check if database save is complete
              if (state is MapDownloadingState && state.done == true) {
                // Trigger home refresh and navigate to home
                homeRefreshNotifier.value = true;
                AppRouter.goHome(context);
              }
            },
            builder: (context, state) {
              switch (state) {
                case FlightMapPreviewLoading():
                  return _buildLoadingState();
                case FlightMapPreviewLoaded():
                  return _previewLoaded(context, state);
                case MapDownloadingState():
                  return state.isDownloaded
                      ? _buildCompletionState(context)
                      : FlightDownloading(
                          airports: airports,
                          downloadingState: state,
                        );
                case FlightMapPreviewError():
                  return _buildErrorState(context, state);
              }
            },
          ),
        ),
      ),
    );
  }

  /// Build loading state UI
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Calculating flight route...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '${airports.departure.code} → ${airports.arrival.code}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Build error state UI
  Widget _buildErrorState(BuildContext context, FlightMapPreviewError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Retry by calling the public retry method
              context.read<FlightPreviewCubit>().retry();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Build completion state UI
  Widget _buildCompletionState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(
            'Download Complete!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Flight has been saved',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Navigating to home...',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _previewLoaded(BuildContext context, FlightMapPreviewLoaded state) {
    return Column(
      children: [
        Expanded(child: FlightMapPreview(flightPreview: state.flightPreview)),
        FlightInfo(airports: airports),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isTooLongFlight
                      ? null
                      : () {
                          context.read<FlightPreviewCubit>().startDownload();
                        },
                  child: Text(
                    state.isTooLongFlight
                        ? 'Too long flight (> 5000km)'
                        : 'Download',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
