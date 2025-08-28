import 'package:flutter/material.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_status/gps_active.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_status/gps_not_granted_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_status/gps_off_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_status/searching_gps_view.dart';

import '../../../viewmodel/flight_screen_state.dart';

class TabGpsData extends StatelessWidget {
  const TabGpsData({required this.state, super.key});

  final FlightScreenLoaded state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildGpsStateContent(state),
    );
  }

  Widget _buildGpsStateContent(FlightScreenLoaded state) {
    switch (state.gpsStatus) {
      case GpsStatus.off:
        return const GpsOffState();
      case GpsStatus.permissionsNotGranted:
        return const GpsNotGrantedState();
      case GpsStatus.searching:
        return const SearchingGpsView();
      case GpsStatus.gpsActive:
      case GpsStatus.weakSignal:
        return GpsActive(state: state);
    }
  }
}
