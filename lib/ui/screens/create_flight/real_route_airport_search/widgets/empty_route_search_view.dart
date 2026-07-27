part of '../real_route_airport_search_screen.dart';

class _EmptyRouteSearchView extends StatelessWidget {
  const _EmptyRouteSearchView({
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
            icon: Icons.travel_explore_rounded,
            title: title,
            message: message,
            actionLabel: searchT.findByFlightNumber,
            onPressed: () => AppRouter.replaceWithFlightNumberSelector(
              context,
              hasPendingFlightUnlock: hasPendingFlightUnlock,
            ),
            // A mixed-up direction is a common cause of empty results.
            secondaryActionLabel: searchT.searchReverse,
            onSecondaryPressed: () => unawaited(cubit.searchReverseDirection()),
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

class _RouteResultsArrivalInput extends StatefulWidget {
  const _RouteResultsArrivalInput({
    required this.inputText,
    required this.selectedAirport,
    required this.selectedAirportIsFavorite,
    required this.homeAirportCode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onClearSelectedAirport,
    required this.onToggleFavoriteForSelected,
  });

  final String inputText;
  final Airport? selectedAirport;
  final bool selectedAirportIsFavorite;
  final String homeAirportCode;
  final Future<void> Function(String value) onSearchChanged;
  final Future<void> Function() onClearSearch;
  final Future<void> Function() onClearSelectedAirport;
  final Future<void> Function() onToggleFavoriteForSelected;

  @override
  State<_RouteResultsArrivalInput> createState() =>
      _RouteResultsArrivalInputState();
}

class _RouteResultsArrivalInputState extends State<_RouteResultsArrivalInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayText);
  }

  @override
  void didUpdateWidget(covariant _RouteResultsArrivalInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = _displayText;
    if (_controller.text != nextText) {
      _controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _selectedAirportLabel {
    final airport = widget.selectedAirport;
    if (airport == null) return '';
    return '${airport.name} (${airport.displayCode})';
  }

  String get _displayText {
    final query = widget.inputText.trim();
    if (query.isNotEmpty) return query;
    return _selectedAirportLabel;
  }

  @override
  Widget build(BuildContext context) {
    final gpsActiveColor = DsSemanticColors.success(context);
    final primary =
        widget.selectedAirport?.primaryCode.trim().toUpperCase() ?? '';
    final selectedAirportCode = primary.isNotEmpty
        ? primary
        : (widget.selectedAirport?.displayCode.trim().toUpperCase() ?? '');
    final isSelectedAirportHome =
        selectedAirportCode.isNotEmpty &&
        widget.homeAirportCode.isNotEmpty &&
        selectedAirportCode == widget.homeAirportCode;

    return SearchInputField(
      controller: _controller,
      onChanged: (value) => unawaited(widget.onSearchChanged(value)),
      hintText: context.t.createFlight.search.arrivalHint,
      isSelected: widget.selectedAirport != null,
      selectedBorderColor: gpsActiveColor,
      onClear: () => unawaited(widget.onClearSearch()),
      suffixActions: widget.selectedAirport != null
          ? [
              if (isSelectedAirportHome)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.home_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    widget.selectedAirportIsFavorite
                        ? Icons.star
                        : Icons.star_border,
                    color: widget.selectedAirportIsFavorite
                        ? DsSemanticColors.warning(context)
                        : null,
                  ),
                  tooltip: widget.selectedAirportIsFavorite
                      ? context.t.createFlight.search.removeFavorite
                      : context.t.createFlight.search.addFavorite,
                  onPressed: () =>
                      unawaited(widget.onToggleFavoriteForSelected()),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.t.createFlight.search.removeSelectedAirport,
                onPressed: () => unawaited(widget.onClearSelectedAirport()),
              ),
            ]
          : const [],
    );
  }
}
