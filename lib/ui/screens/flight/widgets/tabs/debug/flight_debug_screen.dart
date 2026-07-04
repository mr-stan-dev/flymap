import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/debug/debug_tab_view.dart';

class FlightDebugScreen extends StatelessWidget {
  const FlightDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'FlightDebugScreen is only available in debug builds.');
    return Scaffold(
      appBar: AppBar(title: Text(context.t.common.debug)),
      body: BlocBuilder<FlightScreenCubit, FlightScreenState>(
        builder: (context, state) {
          return FlightDebugTabView(state: state, topPadding: 16);
        },
      ),
    );
  }
}
