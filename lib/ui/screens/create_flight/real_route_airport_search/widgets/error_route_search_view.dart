part of '../real_route_airport_search_screen.dart';

class _ErrorRouteSearchView extends StatelessWidget {
  const _ErrorRouteSearchView({
    required this.title,
    required this.message,
    required this.state,
    required this.hasPendingFlightUnlock,
  });

  final String title;
  final String message;
  final RealRouteAirportSearchState state;
  final bool hasPendingFlightUnlock;

  @override
  Widget build(BuildContext context) {
    final searchT = context.t.createFlight.realRouteAirportSearch;
    final cubit = context.read<RealRouteAirportSearchCubit>();
    final homeAirportCode = _airportCode(state.homeAirport);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.selectedDeparture != null) ...[
            SelectedDepartureRow(
              airport: state.selectedDeparture!,
              onEdit: () => unawaited(cubit.handleBackAction()),
            ),
            const SizedBox(height: 12),
          ],
          _RouteResultsArrivalInput(
            inputText: state.searchQuery,
            selectedAirport: state.selectedArrival,
            selectedAirportIsFavorite: state.selectedAirportIsFavorite,
            homeAirportCode: homeAirportCode,
            onSearchChanged: (value) => cubit.reopenArrivalSelection(
              query: value,
              clearSelectedAirport: true,
            ),
            onClearSearch: cubit.reopenArrivalSelection,
            onClearSelectedAirport: () =>
                cubit.reopenArrivalSelection(clearSelectedAirport: true),
            onToggleFavoriteForSelected: cubit.toggleFavoriteForSelectedAirport,
          ),
          const SizedBox(height: 24),
          SearchFallbackAction(
            icon: Icons.cloud_off_rounded,
            title: title,
            message: message,
            // Route-search errors are transient (rate limit, provider down),
            // so lead with Retry; not-found renders the empty view instead.
            actionLabel: context.t.common.retry,
            onPressed: () => unawaited(cubit.searchFlights()),
            secondaryActionLabel: searchT.findByFlightNumber,
            onSecondaryPressed: () => AppRouter.replaceWithFlightNumberSelector(
              context,
              hasPendingFlightUnlock: hasPendingFlightUnlock,
            ),
          ),
        ],
      ),
    );
  }

  String _airportCode(Airport? airport) {
    if (airport == null) return '';
    final primary = airport.primaryCode.trim().toUpperCase();
    if (primary.isNotEmpty) return primary;
    return airport.displayCode.trim().toUpperCase();
  }
}
