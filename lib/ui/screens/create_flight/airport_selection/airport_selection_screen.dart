import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/airport_selection/widgets/flight_search_airport_selection_step.dart';
import 'package:flymap/ui/screens/create_flight/airport_selection/viewmodel/airport_selection_screen_cubit.dart';
import 'package:flymap/ui/screens/create_flight/airport_selection/viewmodel/airport_selection_screen_state.dart';
import 'package:get_it/get_it.dart';

class AirportSelectionScreen extends StatefulWidget {
  const AirportSelectionScreen({super.key});

  @override
  State<AirportSelectionScreen> createState() => _AirportSelectionScreenState();
}

class _AirportSelectionScreenState extends State<AirportSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AirportSelectionScreenCubit(
        airportsDb: GetIt.I.get(),
        favoritesRepository: GetIt.I.get<FavoriteAirportsRepository>(),
      ),
      child:
          BlocConsumer<
            AirportSelectionScreenCubit,
            AirportSelectionScreenState
          >(
            listenWhen: (previous, current) =>
                previous.errorMessage != current.errorMessage ||
                previous.searchQuery != current.searchQuery,
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
            },
            builder: (context, state) {
              final cubit = context.read<AirportSelectionScreenCubit>();
              final selectedAirport = state.selectedAirport;
              final favorites = _filterAirportsForCurrentStep(
                state.favoriteAirports,
                state,
              );
              final favoriteCodes = favorites.map(_airportCode).toSet();
              final popular =
                  _filterAirportsForCurrentStep(state.popularAirports, state)
                      .where(
                        (airport) =>
                            !favoriteCodes.contains(_airportCode(airport)),
                      )
                      .toList();
              final results = _filterAirportsForCurrentStep(
                state.searchResults,
                state,
              );

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
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _onBackPressed(context),
                    ),
                    title: Text(
                      state.step == AirportSelectionStep.departure
                          ? context.t.createFlight.steps.departureTitle
                          : context.t.createFlight.steps.arrivalTitle,
                    ),
                  ),
                  body: SafeArea(
                    top: false,
                    child: FlightSearchAirportSelectionStep(
                      step: state.step,
                      searchController: _searchController,
                      searchQuery: state.searchQuery,
                      isSearchLoading: state.isSearchLoading,
                      selectedAirport: selectedAirport,
                      selectedAirportIsFavorite:
                          state.selectedAirportIsFavorite,
                      favorites: favorites,
                      popular: popular,
                      results: results,
                      onSearchChanged: cubit.searchAirports,
                      onClearSearch: () {
                        _searchController.clear();
                        cubit.searchAirports('');
                      },
                      onToggleFavoriteForSelected:
                          cubit.toggleFavoriteForSelectedAirport,
                      onClearSelectedAirport: () {
                        _searchController.clear();
                        cubit.clearSelectedAirportForCurrentStep();
                      },
                      onSelectAirport: cubit.selectAirport,
                      onToggleFavoriteForAirport:
                          cubit.toggleFavoriteForAirport,
                      onContinue: () =>
                          unawaited(_continue(context, cubit, state)),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  Future<void> _continue(
    BuildContext context,
    AirportSelectionScreenCubit cubit,
    AirportSelectionScreenState state,
  ) async {
    if (state.step == AirportSelectionStep.departure) {
      await cubit.continueFromAirportStep();
      return;
    }

    final departure = state.selectedDeparture;
    final arrival = state.selectedArrival;
    if (departure == null || arrival == null) return;
    if (!context.mounted) return;
    AppRouter.goToFlightPreview(
      context,
      departure: departure,
      arrival: arrival,
    );
  }

  Future<void> _onBackPressed(BuildContext context) async {
    final shouldPop = await context
        .read<AirportSelectionScreenCubit>()
        .handleBackAction();
    if (shouldPop && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  List<Airport> _filterAirportsForCurrentStep(
    List<Airport> airports,
    AirportSelectionScreenState state,
  ) {
    if (state.step != AirportSelectionStep.arrival) return airports;

    final departureCode = _airportCode(state.selectedDeparture);
    if (departureCode.isEmpty) return airports;

    return airports
        .where((airport) => _airportCode(airport) != departureCode)
        .toList();
  }

  String _airportCode(Airport? airport) {
    if (airport == null) return '';
    final primary = airport.primaryCode.trim().toUpperCase();
    if (primary.isNotEmpty) return primary;
    return airport.displayCode.trim().toUpperCase();
  }
}
