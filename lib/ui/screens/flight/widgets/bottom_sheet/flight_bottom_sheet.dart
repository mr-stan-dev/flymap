import 'package:flymap/entity/flight.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/bottom_sheet_loaded.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/bottom_sheet_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FlightBottomSheet extends StatelessWidget {
  final ScrollController scrollController;

  const FlightBottomSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<FlightScreenCubit, FlightScreenState>(
        builder: (BuildContext context, state) {
          switch (state) {
            case FlightScreenLoading():
              return BottomSheetLoading();
            case FlightScreenLoaded():
              return BottomSheetLoaded(scrollController, state);
            case FlightScreenError():
              return BottomSheetLoading();
            case FlightScreenDeleted():
              return BottomSheetLoading();
          }
        },
      ),
    );
  }
}
