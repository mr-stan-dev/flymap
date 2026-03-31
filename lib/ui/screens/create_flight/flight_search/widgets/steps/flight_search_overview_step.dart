import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/info/flight_info_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';

class FlightSearchOverviewStep extends StatelessWidget {
  const FlightSearchOverviewStep({
    required this.state,
    required this.onContinue,
    super.key,
  });

  final FlightSearchScreenState state;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final route = state.flightRoute;
    if (route == null) {
      return const Center(child: Text('Route is not ready yet.'));
    }

    final isDownloadEnabled = !state.isTooLongFlight;
    final buttonText = state.isTooLongFlight
        ? 'Too long flight (> 5000km)'
        : 'Continue';

    return Column(
      children: [
        Expanded(
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: FlightInfoWidget(
                route: route,
                info: state.flightInfo,
                isOverviewLoading: state.isOverviewLoading,
                overviewErrorMessage: state.isOverviewLoading
                    ? null
                    : state.errorMessage,
              ),
            ),
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
                onPressed: isDownloadEnabled ? onContinue : null,
                label: buttonText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
