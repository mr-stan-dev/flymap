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
        appBar: null,
        body: SafeArea(
          top: false,
          bottom: false,
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
        Expanded(
          child: Stack(
            children: [
              // Fullscreen map preview
              Positioned.fill(
                child: FlightMapPreview(flightPreview: state.flightPreview),
              ),

              // Top overlay app bar (transparent with gradient)
              _buildTopAppBar(context, state),

              // Draggable bottom sheet with flight info
              DraggableScrollableSheet(
                initialChildSize: 0.3,
                minChildSize: 0.1,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: FlightInfo(airports: airports),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
        ),
      ],
    );
  }

  Widget _buildTopAppBar(BuildContext context, FlightMapPreviewLoaded state) {
    const Color overlayTextColor = Colors.white;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.flightPreview.departure.code}-${state.flightPreview.arrival.code}',
                        style: const TextStyle(
                          color: overlayTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Flight preview',
                        style: TextStyle(
                          color: overlayTextColor.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
