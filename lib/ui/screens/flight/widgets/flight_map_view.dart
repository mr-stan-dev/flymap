import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/map/flight_map.dart';
import 'package:flymap/ui/screens/flight/widgets/map/flight_map_loading.dart';

import '../viewmodel/flight_screen_cubit.dart';

class FlightMapView extends StatelessWidget {
  final DraggableScrollableController bottomSheetController;

  const FlightMapView({super.key, required this.bottomSheetController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightScreenCubit, FlightScreenState>(
      builder: (BuildContext context, state) {
        switch (state) {
          case FlightScreenLoading():
            return FlightMapLoading();
          case FlightScreenLoaded():
            return FlightMap(flight: state.flight);
          case FlightScreenError():
            return FlightMapLoading();
          case FlightScreenDeleted():
            return FlightMapLoading();
        }
      },
    );
  }
}
