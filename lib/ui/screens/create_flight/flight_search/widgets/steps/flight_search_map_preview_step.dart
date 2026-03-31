import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/map/flight_map_preview_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class FlightSearchMapPreviewStep extends StatelessWidget {
  const FlightSearchMapPreviewStep({
    required this.state,
    required this.onContinue,
    super.key,
  });

  final FlightSearchScreenState state;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final route = state.flightRoute;
    if (state.isPreviewLoading || route == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: FlightMapPreviewWidget(flightRoute: route, flightInfo: state.flightInfo),
        ),
        if (state.isTooLongFlight)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Downloading routes over 5,000 km is not supported yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: PrimaryButton(
                onPressed: state.canContinueFromMap ? onContinue : null,
                label: 'Continue',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
