import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/airport_selection/viewmodel/airport_selection_screen_state.dart';

class FlightSearchAirportSelectionStep extends StatelessWidget {
  const FlightSearchAirportSelectionStep({
    required this.step,
    required this.selectedDeparture,
    required this.searchController,
    required this.searchQuery,
    required this.isSearchLoading,
    required this.selectedAirport,
    required this.selectedAirportIsFavorite,
    required this.favorites,
    required this.recent,
    required this.popular,
    required this.results,
    required this.homeAirportCode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleFavoriteForSelected,
    required this.onClearSelectedAirport,
    required this.onSelectAirport,
    required this.onToggleFavoriteForAirport,
    required this.onEditDeparture,
    required this.onContinue,
    super.key,
  });

  final AirportSelectionStep step;
  final Airport? selectedDeparture;
  final TextEditingController searchController;
  final String searchQuery;
  final bool isSearchLoading;
  final Airport? selectedAirport;
  final bool selectedAirportIsFavorite;
  final List<Airport> favorites;
  final List<Airport> recent;
  final List<Airport> popular;
  final List<Airport> results;
  final String homeAirportCode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleFavoriteForSelected;
  final VoidCallback onClearSelectedAirport;
  final Future<void> Function(Airport airport) onSelectAirport;
  final Future<void> Function(Airport airport) onToggleFavoriteForAirport;
  final VoidCallback onEditDeparture;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final gpsActiveColor = DsSemanticColors.success(context);
    final selectedAirportCode = _airportCode(selectedAirport);
    final isSelectedAirportHome =
        selectedAirportCode.isNotEmpty &&
        homeAirportCode.isNotEmpty &&
        selectedAirportCode == homeAirportCode;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step == AirportSelectionStep.arrival &&
                    selectedDeparture != null) ...[
                  _SelectedDepartureRow(
                    airport: selectedDeparture!,
                    onEdit: onEditDeparture,
                  ),
                  const SizedBox(height: 12),
                ],
                SearchInputField(
                  controller: searchController,
                  onChanged: (value) {
                    if (selectedAirport != null) {
                      onClearSelectedAirport();
                    }
                    onSearchChanged(value);
                  },
                  hintText: step == AirportSelectionStep.departure
                      ? context.t.createFlight.search.departureHint
                      : context.t.createFlight.search.arrivalHint,
                  isSelected: selectedAirport != null,
                  selectedBorderColor: gpsActiveColor,
                  onClear: onClearSearch,
                  suffixActions: selectedAirport != null
                      ? [
                          if (isSelectedAirportHome)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Icon(
                                Icons.home_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                selectedAirportIsFavorite
                                    ? Icons.star
                                    : Icons.star_border,
                                color: selectedAirportIsFavorite
                                    ? DsSemanticColors.warning(context)
                                    : null,
                              ),
                              tooltip: selectedAirportIsFavorite
                                  ? context.t.createFlight.search.removeFavorite
                                  : context.t.createFlight.search.addFavorite,
                              onPressed: onToggleFavoriteForSelected,
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: context
                                .t
                                .createFlight
                                .search
                                .removeSelectedAirport,
                            onPressed: onClearSelectedAirport,
                          ),
                        ]
                      : const [],
                ),
                const SizedBox(height: 12),
                if (isSearchLoading && selectedAirport == null)
                  const Center(child: CircularProgressIndicator())
                else if (searchQuery.isNotEmpty &&
                    results.isEmpty &&
                    selectedAirport == null)
                  _EmptySearchResults(step: step)
                else if (results.isNotEmpty && selectedAirport == null)
                  _SearchResultList(
                    airports: results,
                    onSelectAirport: onSelectAirport,
                  ),
                if (favorites.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.t.createFlight.search.favorites,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AirportChipWrap(
                    airports: favorites,
                    homeAirportCode: homeAirportCode,
                    onSelectAirport: onSelectAirport,
                    showFavoriteTrailingIcon: true,
                    onToggleFavorite: onToggleFavoriteForAirport,
                  ),
                ],
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.t.createFlight.search.recentAirports,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AirportChipWrap(
                    airports: recent,
                    onSelectAirport: onSelectAirport,
                  ),
                ],
                if (popular.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.t.createFlight.search.popularAirports,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AirportChipWrap(
                    airports: popular,
                    onSelectAirport: onSelectAirport,
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: PrimaryButton(
              onPressed: selectedAirport == null ? null : onContinue,
              label: context.t.common.kContinue,
            ),
          ),
        ),
      ],
    );
  }

  String _airportCode(Airport? airport) {
    if (airport == null) return '';
    final primary = airport.primaryCode.trim().toUpperCase();
    if (primary.isNotEmpty) return primary;
    return airport.displayCode.trim().toUpperCase();
  }
}

class _SelectedDepartureRow extends StatelessWidget {
  const _SelectedDepartureRow({required this.airport, required this.onEdit});

  final Airport airport;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flight_takeoff_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '${context.t.flight.info.departure}:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${airport.name} (${airport.displayCode})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                context.t.common.edit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AirportChipWrap extends StatelessWidget {
  const _AirportChipWrap({
    required this.airports,
    required this.onSelectAirport,
    this.homeAirportCode = '',
    this.showFavoriteTrailingIcon = false,
    this.onToggleFavorite,
  });

  final List<Airport> airports;
  final Future<void> Function(Airport airport) onSelectAirport;
  final String homeAirportCode;
  final bool showFavoriteTrailingIcon;
  final Future<void> Function(Airport airport)? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: airports.map((airport) {
        final code = _airportCode(airport);
        final isHomeAirport =
            homeAirportCode.isNotEmpty && code == homeAirportCode;
        return SelectionChip(
          label: context.t.createFlight.search.airportNameCode(
            name: airport.nameShort,
            code: airport.displayCode,
          ),
          leading: isHomeAirport
              ? Icon(
                  Icons.home_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onPressed: () => onSelectAirport(airport),
          onDeleted:
              showFavoriteTrailingIcon &&
                  onToggleFavorite != null &&
                  !isHomeAirport
              ? () => onToggleFavorite!(airport)
              : null,
          deleteIcon: showFavoriteTrailingIcon && !isHomeAirport
              ? Icon(
                  Icons.star,
                  color: DsSemanticColors.warning(context),
                  size: 18,
                )
              : null,
          deleteTooltip: showFavoriteTrailingIcon
              ? context.t.createFlight.search.removeFromFavorites
              : null,
        );
      }).toList(),
    );
  }

  String _airportCode(Airport airport) {
    final primary = airport.primaryCode.trim().toUpperCase();
    if (primary.isNotEmpty) return primary;
    return airport.displayCode.trim().toUpperCase();
  }
}

class _SearchResultList extends StatelessWidget {
  const _SearchResultList({
    required this.airports,
    required this.onSelectAirport,
  });

  final List<Airport> airports;
  final Future<void> Function(Airport airport) onSelectAirport;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: airports.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final airport = airports[index];
        return ListTile(
          onTap: () => onSelectAirport(airport),
          dense: true,
          visualDensity: const VisualDensity(vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            context.t.createFlight.search.airportNameCode(
              name: airport.name,
              code: airport.displayCode,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

class _EmptySearchResults extends StatelessWidget {
  const _EmptySearchResults({required this.step});

  final AirportSelectionStep step;

  @override
  Widget build(BuildContext context) {
    final text = step == AirportSelectionStep.departure
        ? context.t.createFlight.search.noDepartureFound
        : context.t.createFlight.search.noArrivalFound;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
