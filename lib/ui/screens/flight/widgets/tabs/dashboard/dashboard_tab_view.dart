import 'package:flutter/material.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/dashboard_panel.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/gps_live_status_card.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/route_progress_card.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/telemetry_searching_overlay.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/shared/tab_state_placeholder.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/weak_signal_banner.dart';

class FlightDashboardTabView extends StatelessWidget {
  const FlightDashboardTabView({
    required this.state,
    required this.topPadding,
    super.key,
  });

  final FlightScreenState state;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    if (state is FlightScreenLoaded) {
      return _LoadedDashboardTab(
        state: state as FlightScreenLoaded,
        topPadding: topPadding,
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
  const _LoadedDashboardTab({required this.state, required this.topPadding});

  final FlightScreenLoaded state;
  final double topPadding;

  bool get _hasLiveTelemetry =>
      state.gpsStatus == GpsStatus.gpsActive ||
      state.gpsStatus == GpsStatus.weakSignal;
  bool get _isSearching => state.gpsStatus == GpsStatus.searching;
  bool get _showTelemetryCards => _hasLiveTelemetry || _isSearching;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GpsLiveStatusCard(
              gpsStatus: state.gpsStatus,
              gpsData: state.gpsData,
              gpsUpdateTick: state.gpsUpdateTick,
            ),
            if (_showTelemetryCards) ...[
              const SizedBox(height: 12),
              TelemetrySearchingOverlay(
                enabled: _isSearching,
                child: RouteProgressCard(
                  route: state.flight.route,
                  gpsData: state.gpsData,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_showTelemetryCards)
              TelemetrySearchingOverlay(
                enabled: _isSearching,
                child: FlightDashboardPanel(state: state),
              )
            else
              FlightDashboardPanel(state: state),
            if (state.gpsStatus == GpsStatus.weakSignal) ...[
              const SizedBox(height: 12),
              const WeakSignalBanner(),
            ],
          ],
        ),
      ),
    );
  }
}
