import 'package:flutter/material.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/compass_widget.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/gps_not_granted_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/gps_off_state.dart';

class FlightDashboardPanel extends StatelessWidget {
  const FlightDashboardPanel({required this.state, super.key});

  final FlightScreenLoaded state;

  @override
  Widget build(BuildContext context) {
    return SectionCard(child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    switch (state.gpsStatus) {
      case GpsStatus.off:
        return const GpsOffState();
      case GpsStatus.permissionsNotGranted:
        return const GpsNotGrantedState();
      case GpsStatus.searching:
      case GpsStatus.gpsActive:
      case GpsStatus.weakSignal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.flight.dashboard.liveInstruments,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FlightCompassWidget(gpsData: state.gpsData),
          ],
        );
    }
  }
}
