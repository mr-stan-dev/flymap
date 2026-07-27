part of '../real_route_airport_search_screen.dart';

class _FoundRouteSearchView extends StatelessWidget {
  const _FoundRouteSearchView({required this.state});

  final RealRouteAirportSearchState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RealRouteAirportSearchCubit>();
    final searchT = context.t.createFlight.realRouteAirportSearch;
    final selectedFlight = state.selectedMatchedFlight;
    final departure = state.selectedDeparture;
    final arrival = state.selectedArrival;
    final resultsTitle = state.matchedFlights.length == 1
        ? searchT.foundOneTitle
        : searchT.foundManyTitle(count: state.matchedFlights.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (departure != null && arrival != null) ...[
                _RouteResultsHeader(departure: departure, arrival: arrival),
                const SizedBox(height: 24),
              ],
              Text(resultsTitle, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: state.matchedFlights.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final flight = state.matchedFlights[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => cubit.selectFlight(flight),
                  child: _SelectableFlightCard(
                    flight: flight,
                    isSelected: selectedFlight == flight,
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: PrimaryButton(
            label: context.t.common.kContinue,
            onPressed: selectedFlight == null
                ? null
                : cubit.confirmSelectedFlight,
          ),
        ),
      ],
    );
  }
}

class _SelectableFlightCard extends StatelessWidget {
  const _SelectableFlightCard({required this.flight, required this.isSelected});

  final FlightSummary flight;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Same card as the flight-number flow, minus the airport pair (all
    // candidates here share the route shown once in the header above).
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.05)
            : colorScheme.surface,
      ),
      child: FlightSummaryCard(
        summary: flight,
        showBorder: false,
        showAirports: false,
        trailing: Icon(
          isSelected
              ? Icons.check_circle
              : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RouteResultsHeader extends StatelessWidget {
  const _RouteResultsHeader({required this.departure, required this.arrival});

  final Airport departure;
  final Airport arrival;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _RouteAirportSummary(
            airport: departure,
            crossAxisAlignment: CrossAxisAlignment.start,
            textAlign: TextAlign.left,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.arrow_forward,
            size: 20,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: _RouteAirportSummary(
            airport: arrival,
            crossAxisAlignment: CrossAxisAlignment.end,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _RouteAirportSummary extends StatelessWidget {
  const _RouteAirportSummary({
    required this.airport,
    required this.crossAxisAlignment,
    required this.textAlign,
  });

  final Airport airport;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          airport.displayCode,
          textAlign: textAlign,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          airport.nameShort,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (airport.city.isNotEmpty || airport.countryCode.isNotEmpty)
          Text(
            [
              if (airport.city.isNotEmpty) airport.city,
              if (airport.countryCode.isNotEmpty) airport.countryCode,
            ].join(', '),
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }
}
