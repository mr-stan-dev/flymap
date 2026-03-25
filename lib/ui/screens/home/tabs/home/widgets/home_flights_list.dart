import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/size_utils.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/delete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class HomeFlightsList extends StatelessWidget {
  const HomeFlightsList({
    required this.flights,
    required this.selectedSort,
    required this.onSortChanged,
    super.key,
  });

  final List<Flight> flights;
  final HomeFlightsSort selectedSort;
  final Future<void> Function(HomeFlightsSort sort) onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FlightsSectionHeader(
          count: flights.length,
          selectedSort: selectedSort,
          onSortChanged: onSortChanged,
        ),
        const SizedBox(height: 12),
        _buildFlightsContent(context),
      ],
    );
  }

  Widget _buildFlightsContent(BuildContext context) {
    if (flights.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.flight_takeoff,
              color: colorScheme.onSurfaceVariant,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              'No flights yet',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first flight to see route details here.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flights.length,
      itemBuilder: (context, index) {
        final flight = flights[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < flights.length - 1 ? 12 : 0),
          child: _FlightCard(flight: flight),
        );
      },
    );
  }
}

class _FlightsSectionHeader extends StatelessWidget {
  const _FlightsSectionHeader({
    required this.count,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final int count;
  final HomeFlightsSort selectedSort;
  final Future<void> Function(HomeFlightsSort sort) onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Flights ($count)',
            style: context.textTheme.title24Medium,
          ),
        ),
        PopupMenuButton<HomeFlightsSort>(
          initialValue: selectedSort,
          onSelected: onSortChanged,
          itemBuilder: (context) => HomeFlightsSort.values
              .map(
                (sort) => PopupMenuItem<HomeFlightsSort>(
                  value: sort,
                  child: Text(sort.label),
                ),
              )
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_vert, size: 16),
                const SizedBox(width: 6),
                Text(
                  selectedSort.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({required this.flight});

  final Flight flight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final route = flight.route;
    final hasOfflineMap = flight.maps.isNotEmpty;
    final departure = route.departure;
    final arrival = route.arrival;
    final distanceKm = route.distanceInKm.toStringAsFixed(0);
    final offlineSize = _formatOfflineSize(flight);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => AppRouter.goToFlight(context, flight: flight),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${departure.displayCode} -> ${arrival.displayCode}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusChip(
                  label: hasOfflineMap ? 'Saved offline' : 'Needs map',
                  tone: hasOfflineMap
                      ? StatusChipTone.success
                      : StatusChipTone.warning,
                ),
                PopupMenuButton<_FlightCardAction>(
                  tooltip: 'Flight actions',
                  onSelected: (value) =>
                      _onActionSelected(context, value: value, flight: flight),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _FlightCardAction.open,
                      child: Text('Open'),
                    ),
                    PopupMenuItem(
                      value: _FlightCardAction.share,
                      child: Text('Share route'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: _FlightCardAction.delete,
                      child: Text('Delete flight'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${departure.cityWithCountryCode} -> ${arrival.cityWithCountryCode}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetaPill(icon: Icons.route, text: '$distanceKm km'),
                MetaPill(icon: Icons.map_outlined, text: offlineSize),
                MetaPill(
                  icon: Icons.schedule,
                  text: _createdLabel(flight.createdAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onActionSelected(
    BuildContext context, {
    required _FlightCardAction value,
    required Flight flight,
  }) async {
    switch (value) {
      case _FlightCardAction.open:
        AppRouter.goToFlight(context, flight: flight);
      case _FlightCardAction.share:
        AppRouter.goToShareFlight(context, flight: flight);
      case _FlightCardAction.delete:
        final confirmed = await DeleteFlightConfirmationDialog.show(
          context,
          reclaimedBytes: _mapSizeBytes(flight),
        );
        if (confirmed != true || !context.mounted) return;
        final deleted = await context.read<HomeTabCubit>().deleteFlight(
          flight.id,
        );
        if (!deleted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete flight')),
          );
        }
    }
  }

  String _formatOfflineSize(Flight flight) {
    final bytes = _mapSizeBytes(flight);
    if (bytes <= 0) return 'No offline map';
    return SizeUtils.formatBytes(bytes);
  }

  int _mapSizeBytes(Flight flight) {
    if (flight.maps.isEmpty) return 0;
    return flight.maps.fold<int>(0, (sum, map) => sum + map.sizeBytes);
  }

  String _createdLabel(DateTime createdAt) {
    final delta = DateTime.now().difference(createdAt);
    if (delta.inDays >= 1) return '${delta.inDays}d ago';
    if (delta.inHours >= 1) return '${delta.inHours}h ago';
    if (delta.inMinutes >= 1) return '${delta.inMinutes}m ago';
    return 'Just now';
  }
}

enum _FlightCardAction { open, share, delete }

extension _HomeFlightsSortLabel on HomeFlightsSort {
  String get label {
    switch (this) {
      case HomeFlightsSort.mostRecent:
        return 'Most recent';
      case HomeFlightsSort.longestDistance:
        return 'Longest';
      case HomeFlightsSort.alphabetical:
        return 'A-Z';
    }
  }
}
