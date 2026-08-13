import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/widgets/map_debug_sim_controls.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/shared/tab_state_placeholder.dart';

class FlightDebugTabView extends StatefulWidget {
  const FlightDebugTabView({
    required this.state,
    required this.topPadding,
    super.key,
  });

  final FlightScreenState state;
  final double topPadding;

  @override
  State<FlightDebugTabView> createState() => _FlightDebugTabViewState();
}

class _FlightDebugTabViewState extends State<FlightDebugTabView> {
  FlightScreenCubit? _flightCubit;
  int _speed = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = context.read<FlightScreenCubit>();
    if (!identical(_flightCubit, cubit)) {
      _flightCubit = cubit;
      _speed = cubit.debugGpsSimulationSpeedMultiplier;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state is! FlightScreenLoaded) {
      return const FlightTabStatePlaceholder(
        icon: Icons.developer_mode,
        text: 'Debug simulation unavailable',
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, widget.topPadding, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS Simulation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Drives FlightScreenCubit telemetry for all tabs.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MapDebugSimControls(
                        isPlaying:
                            _flightCubit?.isDebugGpsSimulationPlaying ?? false,
                        speedMultiplier: _speed,
                        onTogglePlayPause: _togglePlayPause,
                        onRestart: _restart,
                        onSpeedSelected: _setSpeed,
                      ),
                    ),
                    if (!(_flightCubit?.hasDebugGpsSimulationRoute ??
                        false)) ...[
                      const SizedBox(height: 10),
                      Text(
                        'No route points available for simulation.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePlayPause() {
    final cubit = _flightCubit;
    if (cubit == null) return;
    if (cubit.isDebugGpsSimulationPlaying) {
      cubit.pauseDebugGpsSimulation();
      setState(() {});
      return;
    }
    if (!cubit.hasDebugGpsSimulationRoute) return;

    cubit.setDebugGpsSimulationSpeedMultiplier(_speed);
    cubit.playDebugGpsSimulation();
    setState(() {});
  }

  void _restart() {
    final cubit = _flightCubit;
    if (cubit == null || !cubit.hasDebugGpsSimulationRoute) return;
    cubit.setDebugGpsSimulationSpeedMultiplier(_speed);
    cubit.restartDebugGpsSimulation();
    setState(() {});
  }

  void _setSpeed(int speed) {
    if (_speed == speed || speed <= 0) return;
    _flightCubit?.setDebugGpsSimulationSpeedMultiplier(speed);
    setState(() {
      _speed = speed;
    });
  }
}
