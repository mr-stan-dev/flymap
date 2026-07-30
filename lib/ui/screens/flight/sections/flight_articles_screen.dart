import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/read/read_tab_view.dart';

/// Offline Wikipedia articles for the flight — the former Read tab's
/// content, pushed from the Flight hub.
class FlightArticlesScreen extends StatelessWidget {
  const FlightArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.flight.hub.articlesTitle)),
      body: SafeArea(
        child: BlocBuilder<FlightScreenCubit, FlightScreenState>(
          builder: (context, state) =>
              ReadTabView(state: state, topPadding: 12),
        ),
      ),
    );
  }
}
