import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/info_content.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/shared/tab_state_placeholder.dart';

class FlightInfoTabView extends StatelessWidget {
  const FlightInfoTabView({
    required this.state,
    required this.topPadding,
    super.key,
  });

  final FlightScreenState state;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    if (state is FlightScreenLoaded) {
      final loaded = state as FlightScreenLoaded;
      return FlightInfoContent(
        topPadding: topPadding,
        route: loaded.flight.route,
        info: loaded.flight.info,
      );
    }

    if (state is FlightScreenError) {
      final error = state as FlightScreenError;
      if (error.flight != null) {
        return FlightInfoContent(
          topPadding: topPadding,
          route: error.flight!.route,
          info: error.flight!.info,
        );
      }
    }

    return const FlightTabStatePlaceholder(
      icon: Icons.info_outline,
      text: 'Loading route information...',
    );
  }
}
