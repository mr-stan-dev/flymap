import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flight_card.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/home_flights_list.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/home_summary_header.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class HomeTabLoaded extends StatelessWidget {
  const HomeTabLoaded(this.state, {super.key});

  final HomeTabSuccess state;

  @override
  Widget build(BuildContext context) {
    final inProgressFlights = state.flights
        .where((flight) => flight.status == FlightStatus.inProgress)
        .toList(growable: false);
    final hasInProgressFlights = inProgressFlights.isNotEmpty;
    final listFlights = state.flights
        .where((flight) => flight.status != FlightStatus.inProgress)
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<HomeTabCubit>().refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The in-progress flight IS the hero: while one is active it
                  // replaces the greeting/stats header entirely.
                  if (hasInProgressFlights) ...[
                    Text(
                      context.t.home.flightInProgressTitle,
                      style: context.textTheme.button18Bold,
                    ),
                    const SizedBox(height: 12),
                    for (
                      var index = 0;
                      index < inProgressFlights.length;
                      index++
                    ) ...[
                      HomeFlightCard(
                        flight: inProgressFlights[index],
                        distanceUnit: state.distanceUnit,
                        highlightInProgress: true,
                      ),
                      if (index < inProgressFlights.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ] else
                    HomeSummaryHeader(
                      statistics: state.statistics,
                      displayName: state.displayName,
                      hasInternet: state.hasInternet,
                      hasInProgressFlights: hasInProgressFlights,
                    ),
                  const SizedBox(height: 24),
                  HomeFlightsList(
                    flights: listFlights,
                    distanceUnit: state.distanceUnit,
                    hasCompletedFlights:
                        state.statistics.totalFlights > state.flights.length,
                    onViewAll: () => AppRouter.goToSettingsHistory(context),
                    onAddFirstFlight: () =>
                        AppRouter.goToRouteTypeSelector(context),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRouter.goToRouteTypeSelector(context),
        icon: const Icon(Icons.flight_takeoff),
        label: Text(context.t.home.newFlight),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
