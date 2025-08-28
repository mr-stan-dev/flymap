import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/flight_search_by_airports.dart';
import 'package:get_it/get_it.dart';

/// Home screen widget
class FlightSearchScreen extends StatelessWidget {
  const FlightSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlightSearchScreenCubit(airportsDb: GetIt.I.get()),
      child: const FlightSearchByAirports(),
    );
  }
}
