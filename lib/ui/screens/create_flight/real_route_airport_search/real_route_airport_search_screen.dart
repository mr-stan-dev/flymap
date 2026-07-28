import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_number_search/widgets/flight_summary_card.dart';
import 'package:flymap/ui/screens/create_flight/widgets/flight_search_loading_view.dart';
import 'package:flymap/ui/screens/create_flight/flight_number_search/widgets/search_fallback_action.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/viewmodel/airport_selection_screen_state.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/widgets/flight_search_airport_selection_step.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/widgets/selected_departure_row.dart';
import 'package:flymap/ui/screens/create_flight/travel_date/travel_date_pick_screen.dart';
import 'package:get_it/get_it.dart';

import 'viewmodel/real_route_airport_search_cubit.dart';
import 'viewmodel/real_route_airport_search_state.dart';

part 'widgets/empty_route_search_view.dart';
part 'widgets/error_route_search_view.dart';
part 'widgets/found_route_search_view.dart';
part 'widgets/initial_route_search_view.dart';
part 'widgets/loading_route_search_view.dart';
part 'widgets/route_results_router_view.dart';

class RealRouteAirportSearchScreen extends StatefulWidget {
  const RealRouteAirportSearchScreen({
    this.hasPendingFlightUnlock = false,
    super.key,
  });

  final bool hasPendingFlightUnlock;

  @override
  State<RealRouteAirportSearchScreen> createState() =>
      _RealRouteAirportSearchScreenState();
}

class _RealRouteAirportSearchScreenState
    extends State<RealRouteAirportSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RealRouteAirportSearchCubit(
        airportsDb: GetIt.I.get(),
        favoritesRepository: GetIt.I.get<FavoriteAirportsRepository>(),
        onboardingRepository: GetIt.I.get<OnboardingRepository>(),
        recentAirportsRepository: GetIt.I.get<RecentAirportsRepository>(),
        searchFlightsByRouteUseCase: GetIt.I.get(),
      ),
      child:
          BlocConsumer<
            RealRouteAirportSearchCubit,
            RealRouteAirportSearchState
          >(
            listenWhen: (previous, current) =>
                previous.errorMessage != current.errorMessage ||
                previous.searchQuery != current.searchQuery ||
                previous.pendingSelection != current.pendingSelection,
            listener: (context, state) {
              if (_searchController.text != state.searchQuery) {
                _searchController.value = TextEditingValue(
                  text: state.searchQuery,
                  selection: TextSelection.collapsed(
                    offset: state.searchQuery.length,
                  ),
                );
              }
              if (state.errorMessage != null &&
                  state.errorMessage!.isNotEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
              final selection = state.pendingSelection;
              if (selection != null) {
                // Flight confirmed — the date is picked on its own step,
                // which fetches this number's 7-day schedule itself.
                AppRouter.goToTravelDatePick(
                  context,
                  args: TravelDatePickArgs(
                    departure: selection.departure,
                    arrival: selection.arrival,
                    flightNumber: selection.flightNumber,
                    fr24Id: selection.fr24Id,
                    hasPendingFlightUnlock: widget.hasPendingFlightUnlock,
                  ),
                );
                context
                    .read<RealRouteAirportSearchCubit>()
                    .clearPendingSelection();
              }
            },
            builder: (context, state) {
              final cubit = context.read<RealRouteAirportSearchCubit>();
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) async {
                  if (didPop) return;
                  final shouldPop = await cubit.handleBackAction();
                  if (shouldPop && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(
                      context.t.createFlight.realRouteAirportSearch.title,
                    ),
                  ),
                  body: SafeArea(
                    top: false,
                    child: switch (state.view) {
                      RealRouteAirportSearchView.airportSelection =>
                        _InitialRouteSearchView(
                          state: state,
                          searchController: _searchController,
                        ),
                      RealRouteAirportSearchView.results =>
                        _RouteResultsRouterView(
                          state: state,
                          hasPendingFlightUnlock: widget.hasPendingFlightUnlock,
                        ),
                    },
                  ),
                ),
              );
            },
          ),
    );
  }
}
