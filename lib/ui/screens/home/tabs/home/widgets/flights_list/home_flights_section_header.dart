import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flights_sort_label.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class HomeFlightsSectionHeader extends StatelessWidget {
  const HomeFlightsSectionHeader({
    required this.count,
    required this.selectedSort,
    required this.onSortChanged,
    super.key,
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
            context.t.home.flightsCount(count: count),
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
