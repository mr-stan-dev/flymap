import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
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
        onboardingRepository: GetIt.I.get<OnboardingRepository>(),
        recentAirportsRepository: GetIt.I.get<RecentAirportsRepository>(),
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
              final filteredFavorites = _filterAirportsForCurrentStep(
                state.favoriteAirports,
                state,
              );
              final homeAirport = _filterHomeAirportForCurrentStep(state);
              final favorites = _pinHomeAirportFirst(
                filteredFavorites,
                homeAirport,
              );
              final favoriteCodes = favorites.map(_airportCode).toSet();
              final recentCodes = <String>{};
              final recent =
                  _filterAirportsForCurrentStep(
                    state.recentAirports,
                    state,
                  ).where((airport) {
                    final code = _airportCode(airport);
                    if (favoriteCodes.contains(code)) return false;
                    recentCodes.add(code);
                    return true;
                  }).toList();
              final popular =
                  _filterAirportsForCurrentStep(state.popularAirports, state)
                      .where(
                        (airport) =>
                            !favoriteCodes.contains(_airportCode(airport)) &&
                            !recentCodes.contains(_airportCode(airport)),
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
                    _popOrGoHome(context);
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
                      selectedDeparture: state.selectedDeparture,
                      searchController: _searchController,
                      searchQuery: state.searchQuery,
                      isSearchLoading: state.isSearchLoading,
                      selectedAirport: selectedAirport,
                      selectedAirportIsFavorite:
                          state.selectedAirportIsFavorite,
                      favorites: favorites,
                      recent: recent,
                      popular: popular,
                      results: results,
                      homeAirportCode: _airportCode(homeAirport),
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
                      onEditDeparture: () =>
                          unawaited(cubit.handleBackAction()),
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
    await cubit.saveSelectedAirportsAsRecent();
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
      _popOrGoHome(context);
    }
  }

  void _popOrGoHome(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    AppRouter.goHome(context);
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

  Airport? _filterHomeAirportForCurrentStep(AirportSelectionScreenState state) {
    final home = state.homeAirport;
    if (home == null) return null;
    if (state.step != AirportSelectionStep.arrival) return home;
    final departureCode = _airportCode(state.selectedDeparture);
    if (departureCode.isEmpty) return home;
    return _airportCode(home) == departureCode ? null : home;
  }

  List<Airport> _pinHomeAirportFirst(List<Airport> favorites, Airport? home) {
    if (home == null) return favorites;
    final homeCode = _airportCode(home);
    final filtered = favorites
        .where((airport) => _airportCode(airport) != homeCode)
        .toList();
    return [home, ...filtered];
  }

  String _airportCode(Airport? airport) {
    if (airport == null) return '';
    final primary = airport.primaryCode.trim().toUpperCase();
    if (primary.isNotEmpty) return primary;
    return airport.displayCode.trim().toUpperCase();
  }
}
