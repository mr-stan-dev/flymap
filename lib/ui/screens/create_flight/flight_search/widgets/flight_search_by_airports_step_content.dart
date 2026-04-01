import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_download_completion.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/flight_search_by_airports_step_meta.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/steps/flight_search_airport_selection_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/steps/flight_search_downloading_view.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/steps/flight_search_map_preview_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/steps/flight_search_overview_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/steps/flight_search_wikipedia_articles_step.dart';

class FlightSearchByAirportsStepContent extends StatelessWidget {
  const FlightSearchByAirportsStepContent({
    required this.state,
    required this.searchController,
    required this.showDownloadSuccess,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleFavoriteForSelected,
    required this.onClearSelectedAirport,
    required this.onSelectAirport,
    required this.onToggleFavoriteForAirport,
    required this.onContinueFromAirportStep,
    required this.onContinueFromMap,
    required this.onSelectMapDetailLevel,
    required this.onContinueFromOverview,
    required this.onToggleWikiArticle,
    required this.onToggleAllWikiArticles,
    required this.isProUser,
    required this.onStartDownload,
    required this.onCancelDownload,
    super.key,
  });

  final FlightSearchScreenState state;
  final TextEditingController searchController;
  final bool showDownloadSuccess;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleFavoriteForSelected;
  final VoidCallback onClearSelectedAirport;
  final Future<void> Function(Airport airport) onSelectAirport;
  final Future<void> Function(Airport airport) onToggleFavoriteForAirport;
  final VoidCallback onContinueFromAirportStep;
  final VoidCallback onContinueFromMap;
  final ValueChanged<MapDetailLevel> onSelectMapDetailLevel;
  final VoidCallback onContinueFromOverview;
  final ValueChanged<String> onToggleWikiArticle;
  final VoidCallback onToggleAllWikiArticles;
  final bool isProUser;
  final VoidCallback onStartDownload;
  final VoidCallback onCancelDownload;

  @override
  Widget build(BuildContext context) {
    if (showDownloadSuccess) {
      return const FlightDownloadCompletion();
    }

    if (state.isDownloading) {
      return FlightSearchDownloadingView(
        state: state,
        onCancel: onCancelDownload,
      );
    }

    switch (state.step) {
      case CreateFlightStep.departure:
      case CreateFlightStep.arrival:
        final selectedAirport = state.step == CreateFlightStep.departure
            ? state.selectedDeparture
            : state.selectedArrival;
        final favorites = filterAirportsForCurrentStep(
          state.favoriteAirports,
          state,
        );
        final favoriteCodes = favorites.map(airportCode).toSet();
        final popular =
            filterAirportsForCurrentStep(state.popularAirports, state)
                .where(
                  (airport) => !favoriteCodes.contains(airportCode(airport)),
                )
                .toList();
        final results = filterAirportsForCurrentStep(
          state.searchResults,
          state,
        );

        return FlightSearchAirportSelectionStep(
          step: state.step,
          searchController: searchController,
          searchQuery: state.searchQuery,
          isSearchLoading: state.isSearchLoading,
          selectedAirport: selectedAirport,
          selectedAirportIsFavorite: state.selectedAirportIsFavorite,
          favorites: favorites,
          popular: popular,
          results: results,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
          onToggleFavoriteForSelected: onToggleFavoriteForSelected,
          onClearSelectedAirport: onClearSelectedAirport,
          onSelectAirport: onSelectAirport,
          onToggleFavoriteForAirport: onToggleFavoriteForAirport,
          onContinue: onContinueFromAirportStep,
        );
      case CreateFlightStep.mapPreview:
        return FlightSearchMapPreviewStep(
          state: state,
          isProUser: isProUser,
          onContinue: onContinueFromMap,
          onSelectMapDetailLevel: onSelectMapDetailLevel,
        );
      case CreateFlightStep.overview:
        return FlightSearchOverviewStep(
          state: state,
          onContinue: onContinueFromOverview,
        );
      case CreateFlightStep.wikipediaArticles:
        return FlightSearchWikipediaArticlesStep(
          state: state,
          isProUser: isProUser,
          onToggleArticle: onToggleWikiArticle,
          onToggleAll: onToggleAllWikiArticles,
          onStartDownload: onStartDownload,
        );
    }
  }
}
