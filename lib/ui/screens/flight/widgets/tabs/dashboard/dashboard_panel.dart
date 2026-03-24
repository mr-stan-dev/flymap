import 'package:flutter/material.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/compass_widget.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/gps_not_granted_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/gps_off_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/searching_gps_view.dart';

class FlightDashboardPanel extends StatelessWidget {
  const FlightDashboardPanel({required this.state, super.key});

  final FlightScreenLoaded state;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(content: _buildContent());
  }

  Widget _buildContent() {
    switch (state.gpsStatus) {
      case GpsStatus.off:
        return const GpsOffState();
      case GpsStatus.permissionsNotGranted:
        return const GpsNotGrantedState();
      case GpsStatus.searching:
        return const SearchingGpsView();
      case GpsStatus.gpsActive:
      case GpsStatus.weakSignal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live instruments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FlightCompassWidget(gpsData: state.gpsData),
          ],
        );
    }
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: content,
    );
  }
}
