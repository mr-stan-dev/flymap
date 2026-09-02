import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/day_night/route_sun_event_forecast.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_gps_status_badge.dart';

class FlightMapGpsBadgeOverlay extends StatelessWidget {
  const FlightMapGpsBadgeOverlay({
    required this.topOffset,
    this.sunEventForecast,
    this.onGpsHelpTap,
    super.key,
  });

  final double topOffset;
  final RouteSunEventForecast? sunEventForecast;
  final VoidCallback? onGpsHelpTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      left: 16,
      right: 92,
      child: Align(
        alignment: Alignment.topLeft,
        child: BlocBuilder<FlightScreenCubit, FlightScreenState>(
          buildWhen: (previous, current) {
            if (previous is FlightScreenLoaded &&
                current is FlightScreenLoaded) {
              return previous.gps.status != current.gps.status ||
                  previous.gps.updateTick != current.gps.updateTick ||
                  previous.gps.data?.accuracy != current.gps.data?.accuracy ||
                  previous.gps.mapPosition != current.gps.mapPosition;
            }
            return previous.runtimeType != current.runtimeType;
          },
          builder: (context, state) {
            if (state is! FlightScreenLoaded) {
              return const SizedBox.shrink();
            }
            return MapGpsStatusBadge(
              gpsStatus: state.gps.status,
              gpsData: state.gps.data,
              mapPosition: state.gps.mapPosition,
              sunEventForecast: sunEventForecast,
              onHelpTap: _showGpsHelpAction(state.gps) ? onGpsHelpTap : null,
            );
          },
        ),
      ),
    );
  }

  bool _showGpsHelpAction(FlightGpsState gps) {
    if (gps.status == GpsStatus.searching || gps.status == GpsStatus.off) {
      return true;
    }
    if (gps.status != GpsStatus.gpsActive &&
        gps.status != GpsStatus.weakSignal) {
      return false;
    }
    final accuracy = gps.data?.accuracy;
    return accuracy == null || accuracy > 15;
  }
}
