part of '../real_route_airport_search_screen.dart';

class _LoadingRouteSearchView extends StatelessWidget {
  const _LoadingRouteSearchView();

  @override
  Widget build(BuildContext context) {
    final searchT = context.t.createFlight.realRouteAirportSearch;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: SingleChildScrollView(
        child: FlightSearchLoadingView(
          stages: [searchT.loading, searchT.loadingHint],
        ),
      ),
    );
  }
}
