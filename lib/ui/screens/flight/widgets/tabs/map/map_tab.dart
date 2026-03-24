import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_tab_loading.dart';

class FlightMapTabView extends StatelessWidget {
  const FlightMapTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightScreenCubit, FlightScreenState>(
      builder: (BuildContext context, state) {
        switch (state) {
          case FlightScreenLoading():
            return const FlightMapTabLoading();
          case FlightScreenLoaded():
            return FlightMap(flight: state.flight);
          case FlightScreenError():
            return const FlightMapTabLoading();
          case FlightScreenDeleted():
            return const FlightMapTabLoading();
        }
      },
    );
  }
}
