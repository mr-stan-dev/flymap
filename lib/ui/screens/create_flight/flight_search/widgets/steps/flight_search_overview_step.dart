import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
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
      return Center(child: Text(context.t.createFlight.overview.routeNotReady));
    }

    return Column(
      children: [
        Expanded(
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
        Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: PrimaryButton(
            onPressed: onContinue,
            label: context.t.common.kContinue,
          ),
        ),
      ],
    );
  }
}
