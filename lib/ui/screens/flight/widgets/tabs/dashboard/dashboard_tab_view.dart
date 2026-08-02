import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/dashboard_panel.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/gps_live_status_card.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/motion/flight_motion_section.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/telemetry_searching_overlay.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/shared/tab_state_placeholder.dart';

class FlightDashboardTabView extends StatelessWidget {
  const FlightDashboardTabView({
    required this.state,
    required this.topPadding,
    this.onGpsHelpTap,
    super.key,
  });

  final FlightScreenState state;
  final double topPadding;
  final VoidCallback? onGpsHelpTap;

  @override
  Widget build(BuildContext context) {
    if (state is FlightScreenLoaded) {
      return _LoadedDashboardTab(
        state: state as FlightScreenLoaded,
        topPadding: topPadding,
        onGpsHelpTap: onGpsHelpTap,
      );
    }

    if (state is FlightScreenError) {
      return FlightTabStatePlaceholder(
        icon: Icons.error_outline,
        text: (state as FlightScreenError).message,
      );
    }

    return FlightTabStatePlaceholder(
      icon: Icons.sensors,
      text: context.t.flight.dashboard.preparingDashboard,
    );
  }
}

class _LoadedDashboardTab extends StatelessWidget {
  const _LoadedDashboardTab({
    required this.state,
    required this.topPadding,
    this.onGpsHelpTap,
  });

  final FlightScreenLoaded state;
  final double topPadding;
  final VoidCallback? onGpsHelpTap;

  bool get _hasLiveTelemetry =>
      state.gps.status == GpsStatus.gpsActive ||
      state.gps.status == GpsStatus.weakSignal;
  bool get _isSearching => state.gps.status == GpsStatus.searching;
  bool get _showTelemetryCards => _hasLiveTelemetry || _isSearching;
  bool get _showGpsHelpAction {
    if (state.gps.status == GpsStatus.searching ||
        state.gps.status == GpsStatus.off) {
      return true;
    }
    if (state.gps.status != GpsStatus.gpsActive &&
        state.gps.status != GpsStatus.weakSignal) {
      return false;
    }
    final accuracy = state.gps.data?.accuracy;
    return accuracy == null || accuracy > 15;
  }

  @override
  Widget build(BuildContext context) {
    return _buildDashboardContent();
  }

  Widget _buildDashboardContent() {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GpsLiveStatusCard(
              gpsStatus: state.gps.status,
              gpsData: state.gps.data,
              gpsLastFixAt: state.gps.lastFixAt,
              onHelpTap: _showGpsHelpAction ? onGpsHelpTap : null,
            ),
            const SizedBox(height: 12),
            if (_showTelemetryCards)
              TelemetrySearchingOverlay(
                enabled: _isSearching && state.gps.lastFixAt == null,
                child: FlightDashboardPanel(state: state),
              )
            else
              FlightDashboardPanel(state: state),
            const SizedBox(height: 12),
            // G-force + cabin pressure are secondary, and work without a GPS
            // fix, so they sit at the very bottom of the dashboard.
            const FlightMotionSection(),
          ],
        ),
      ),
    );
  }
}
