import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/home_flights_list.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/home_summary_header.dart';
import 'package:go_router/go_router.dart';

class HomeTabLoaded extends StatelessWidget {
  const HomeTabLoaded(this.state, {super.key});

  final HomeTabSuccess state;

  @override
  Widget build(BuildContext context) {
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
                  HomeSummaryHeader(statistics: state.statistics),
                  const SizedBox(height: 24),
                  HomeFlightsList(
                    flights: state.flights,
                    selectedSort: state.sort,
                    onSortChanged: context.read<HomeTabCubit>().setSort,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.flightSearchRoute),
        icon: const Icon(Icons.flight_takeoff),
        label: Text(context.t.home.newFlight),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
