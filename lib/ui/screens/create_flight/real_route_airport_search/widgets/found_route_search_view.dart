part of '../real_route_airport_search_screen.dart';

class _FoundRouteSearchView extends StatefulWidget {
  const _FoundRouteSearchView({required this.state});

  final RealRouteAirportSearchState state;

  @override
  State<_FoundRouteSearchView> createState() => _FoundRouteSearchViewState();
}

class _FoundRouteSearchViewState extends State<_FoundRouteSearchView> {
  /// Two-stage flow: pick a flight from the compact list, then (animated)
  /// the same layout as the flight-number flow — the picked strip on top,
  /// the inline date section below.
  FlightSummary? _pickedFlight;
  TravelDateSelection? _dateSelection;
  bool _dateBusy = false;

  @override
  void initState() {
    super.initState();
    // A single match needs no list stage — jump straight to the date.
    if (widget.state.matchedFlights.length == 1) {
      _pickedFlight = widget.state.matchedFlights.single;
    }
  }

  @override
  void didUpdateWidget(covariant _FoundRouteSearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.matchedFlights != widget.state.matchedFlights) {
      _pickedFlight = widget.state.matchedFlights.length == 1
          ? widget.state.matchedFlights.single
          : null;
      _dateSelection = null;
      _dateBusy = false;
    }
  }

  void _pickFlight(FlightSummary flight) {
    context.read<RealRouteAirportSearchCubit>().selectFlight(flight);
    setState(() {
      _pickedFlight = flight;
      _dateSelection = null;
      _dateBusy = false;
    });
  }

  void _backToList() {
    setState(() {
      _pickedFlight = null;
      _dateSelection = null;
      _dateBusy = false;
    });
  }

  void _continueToOverview(FlightSummary flight) {
    final state = widget.state;
    final departure = flight.departure ?? state.selectedDeparture;
    final arrival = flight.arrival ?? state.selectedArrival;
    final number = (flight.flightNumber ?? '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim()
        .toUpperCase();
    if (departure == null || arrival == null || number.isEmpty) return;
    final screen = context
        .findAncestorStateOfType<_RealRouteAirportSearchScreenState>();
    AppRouter.goToFlightOverview(
      context,
      departure: departure,
      arrival: arrival,
      flightNumber: number,
      fr24Id: _dateSelection?.fr24Id ?? flight.fr24Id,
      schedule: _dateSelection?.schedule,
      hasPendingFlightUnlock: screen?.widget.hasPendingFlightUnlock ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchT = context.t.createFlight.realRouteAirportSearch;
    final state = widget.state;
    final picked = _pickedFlight;
    // The route lives ONCE in the title (the list items are airline-led);
    // after a pick the title flips to the single-flight phrasing.
    final route = [
      state.selectedDeparture?.displayCode,
      state.selectedArrival?.displayCode,
    ].whereType<String>().where((code) => code.isNotEmpty).join(' → ');
    final resultsTitle = picked != null
        ? context.t.createFlight.flightNumberSearch.foundTitle
        : state.matchedFlights.length == 1
        ? searchT.foundOneTitle(route: route)
        : searchT.foundManyTitle(
            count: state.matchedFlights.length,
            route: route,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Text(
            resultsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: picked == null ? _flightList(state) : _pickedStage(picked),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: PrimaryButton(
            label: picked == null || _dateSelection != null
                ? context.t.common.kContinue
                // The button IS the explicit dateless choice.
                : context.t.createFlight.travelDate.skipDate,
            onPressed: picked == null || _dateBusy
                ? null
                : () => _continueToOverview(picked),
          ),
        ),
      ],
    );
  }

  Widget _flightList(RealRouteAirportSearchState state) {
    return ListView.separated(
      key: const ValueKey('route-flight-list'),
      padding: EdgeInsets.zero,
      itemCount: state.matchedFlights.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final flight = state.matchedFlights[index];
        return CompactFlightStrip(
          summary: flight,
          // Airline + number is how users recognise THEIR flight here;
          // the shared route sits in the title, recorded facts are noise.
          showRoute: false,
          onTap: () => _pickFlight(flight),
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }

  Widget _pickedStage(FlightSummary picked) {
    return ListView(
      key: const ValueKey('route-picked-stage'),
      padding: EdgeInsets.zero,
      children: [
        TravelDateSection(
          key: ValueKey('date-${picked.flightNumber}-${picked.fr24Id}'),
          departure: picked.departure ?? widget.state.selectedDeparture!,
          arrival: picked.arrival ?? widget.state.selectedArrival!,
          flightNumber: picked.flightNumber ?? '',
          confirmedFlight: picked,
          stripShowRoute: false,
          // Tapping the strip goes back to the list of flights.
          onStripTap: _isSingleFlight ? null : _backToList,
          stripTrailing: _isSingleFlight
              ? null
              : Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          onSelectionChanged: (selection) =>
              setState(() => _dateSelection = selection),
          onBusyChanged: (busy) => setState(() => _dateBusy = busy),
        ),
      ],
    );
  }

  bool get _isSingleFlight => widget.state.matchedFlights.length <= 1;
}
