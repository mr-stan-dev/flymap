import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/flight_search_by_airports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Home screen widget
class FlightSearchScreen extends StatelessWidget {
  const FlightSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlightSearchScreenCubit(),
      child: const FlightSearchByAirports(),
    );
  }
}
