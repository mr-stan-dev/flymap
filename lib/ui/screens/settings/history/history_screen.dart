import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flymap/ui/screens/flight/widgets/complete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/flight/widgets/delete_flight_confirmation_dialog.dart';
import 'package:flymap/domain/usecase/complete_flight_use_case.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';
import 'package:flymap/domain/usecase/restore_flight_use_case.dart';
import 'package:flymap/size_utils.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:flymap/utils/route_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';
import 'package:get_it/get_it.dart';

import 'viewmodel/history_cubit.dart';
import 'viewmodel/history_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(
        repository: GetIt.I<FlightRepository>(),
        unitsRepository: GetIt.I<MetricUnitsRepository>(),
        deleteFlightUseCase: GetIt.I<DeleteFlightUseCase>(),
        completeFlightUseCase: GetIt.I<CompleteFlightUseCase>(),
        restoreFlightUseCase: GetIt.I<RestoreFlightUseCase>(),
      ),
      child: const _HistoryContent(),
    );
  }
}

class _HistoryContent extends StatefulWidget {
  const _HistoryContent();

  @override
  State<_HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends State<_HistoryContent> {
  bool _isSearching = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.t.settings.historySearchHint,
                  border: InputBorder.none,
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value.trim()),
              )
            : Text(context.t.settings.historyTitle),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _query = '';
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return LoadingStateView(title: context.t.settings.historyLoading);
          }
          if (state is HistoryError) {
            return ErrorStateView(
              title: context.t.settings.historyLoadError,
              message: state.message,
              onRetry: () => context.read<HistoryCubit>().load(),
            );
          }

          final success = state as HistorySuccess;
          final visibleItems = _filterItems(success.items);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              if (!_isSearching) ...[
                _HistorySummaryCard(
                  totalFlights: success.totalFlights,
                  totalDistance: success.formattedTotalDistance,
                ),
                const SizedBox(height: 12),
              ],
              _HistoryListHeader(
                sort: success.sort,
                onSortChanged: (sort) =>
                    context.read<HistoryCubit>().setSort(sort),
              ),
              if (visibleItems.isEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  _query.isEmpty
                      ? context.t.settings.historyEmpty
                      : context.t.settings.historyNoResults,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else
                ...visibleItems.map(
                  (item) => _HistoryTile(
                    item: item,
                    distanceUnit: success.distanceUnit,
                    dateDisplayFormat: success.dateDisplayFormat,
                    onActionSelected: (action) =>
                        _onHistoryActionSelected(context, item, action),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onHistoryActionSelected(
    BuildContext context,
    HistoryItem item,
    _HistoryItemAction action,
  ) async {
    switch (action) {
      case _HistoryItemAction.restore:
        final ok = await context.read<HistoryCubit>().restoreFlight(
          item.flight.id,
        );
        if (!context.mounted) return;
        if (ok) {
          homeRefreshNotifier.value = true;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? context.t.settings.historyRestoreSuccess
                  : context.t.settings.historyRestoreError,
            ),
          ),
        );
      case _HistoryItemAction.complete:
        final result = await CompleteFlightConfirmationDialog.show(context);
        if (result == null || !context.mounted) return;
        final ok = await context.read<HistoryCubit>().completeFlight(
          flightId: item.flight.id,
          deleteOfflineData: result.deleteOfflineData,
        );
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.home.failedDeleteFlight)),
          );
        }
      case _HistoryItemAction.deleteOfflineData:
        final confirmed = await _showDeleteOfflineDataDialog(
          context,
          item.flight,
        );
        if (confirmed != true || !context.mounted) return;
        final ok = await context.read<HistoryCubit>().completeFlight(
          flightId: item.flight.id,
          deleteOfflineData: true,
        );
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.home.failedDeleteFlight)),
          );
        }
      case _HistoryItemAction.deleteFlight:
        final confirmed = await DeleteFlightConfirmationDialog.show(
          context,
          reclaimedBytes: _offlineBytes(item.flight),
        );
        if (confirmed != true || !context.mounted) return;
        final ok = await context.read<HistoryCubit>().deleteFlight(
          item.flight.id,
        );
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.home.failedDeleteFlight)),
          );
        }
    }
  }

  Future<bool?> _showDeleteOfflineDataDialog(
    BuildContext context,
    Flight flight,
  ) {
    final bytes = _offlineBytes(flight);
    final size = SizeUtils.formatBytes(bytes);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t.settings.historyDeleteOfflineData),
        content: Text(
          'This removes offline map and saved articles.\n\nSpace to be regained: $size.',
        ),
        actions: [
          SecondaryButton(
            label: context.t.common.cancel,
            onPressed: () => Navigator.of(context).pop(false),
            expand: false,
          ),
          DestructiveButton(
            label: context.t.flight.yes,
            onPressed: () => Navigator.of(context).pop(true),
            expand: false,
          ),
        ],
      ),
    );
  }

  int _offlineBytes(Flight flight) {
    final mapBytes = flight.maps.fold<int>(
      0,
      (sum, map) => sum + map.sizeBytes,
    );
    final articleBytes = flight.info.articles.fold<int>(
      0,
      (sum, article) => sum + article.sizeBytes,
    );
    return mapBytes + articleBytes;
  }

  List<HistoryItem> _filterItems(List<HistoryItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      final route = item.flight.route;
      final dep = route.departure;
      final arr = route.arrival;
      final haystack = <String>[
        dep.city,
        arr.city,
        dep.name,
        arr.name,
        dep.iataCode,
        arr.iataCode,
        dep.icaoCode,
        arr.icaoCode,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.totalFlights,
    required this.totalDistance,
  });

  final int totalFlights;
  final String totalDistance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryValue(
              label: context.t.settings.historyFlightsLabel,
              value: '$totalFlights',
            ),
          ),
          Expanded(
            child: _SummaryValue(
              label: context.t.settings.historyDistanceLabel,
              value: totalDistance,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _HistoryListHeader extends StatelessWidget {
  const _HistoryListHeader({required this.sort, required this.onSortChanged});

  final HistorySort sort;
  final ValueChanged<HistorySort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.t.settings.historyAllFlights,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        PopupMenuButton<HistorySort>(
          onSelected: onSortChanged,
          itemBuilder: (_) => [
            PopupMenuItem(
              value: HistorySort.name,
              child: Text(context.t.settings.historySortName),
            ),
            PopupMenuItem(
              value: HistorySort.distance,
              child: Text(context.t.settings.historySortDistance),
            ),
            PopupMenuItem(
              value: HistorySort.date,
              child: Text(context.t.settings.historySortDate),
            ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_sortLabel(context, sort)),
              const SizedBox(width: 6),
              const Icon(Icons.swap_vert, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  String _sortLabel(BuildContext context, HistorySort value) {
    return switch (value) {
      HistorySort.name => context.t.settings.historySortName,
      HistorySort.distance => context.t.settings.historySortDistance,
      HistorySort.date => context.t.settings.historySortDate,
    };
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.distanceUnit,
    required this.dateDisplayFormat,
    required this.onActionSelected,
  });

  final HistoryItem item;
  final DistanceUnit distanceUnit;
  final DateDisplayFormat dateDisplayFormat;
  final ValueChanged<_HistoryItemAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final route = item.flight.route;
    final distanceLabel = UnitFormatUtils.formatDistanceApprox(
      route.displayDistanceKm.toDouble(),
      distanceUnit,
    );
    final dateSource = item.flight.status == FlightStatus.completed
        ? (item.flight.completedAt ?? item.flight.createdAt)
        : item.flight.createdAt;
    final dateLabel = UnitFormatUtils.formatDate(
      dateSource,
      format: dateDisplayFormat,
    );

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      title: Text(
        RouteUtils.routeCities(route),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${RouteUtils.routeCountries(context, route)} • $distanceLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StatusChip(status: item.flight.status),
              const SizedBox(width: 8),
              _MapChip(flight: item.flight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<_HistoryItemAction>(
        tooltip: context.t.home.flightActions,
        onSelected: onActionSelected,
        itemBuilder: (_) => _menuItems(context),
      ),
    );
  }

  List<PopupMenuEntry<_HistoryItemAction>> _menuItems(BuildContext context) {
    final status = item.flight.status;
    final hasOfflineData =
        item.flight.maps.isNotEmpty || item.flight.info.articles.isNotEmpty;
    final travelDate = item.flight.schedule?.travelDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hasPastTravelDate =
        travelDate != null &&
        DateTime(
          travelDate.year,
          travelDate.month,
          travelDate.day,
        ).isBefore(today);
    final canRestore = hasOfflineData && !hasPastTravelDate;

    if (status == FlightStatus.completed) {
      return [
        if (canRestore)
          PopupMenuItem(
            value: _HistoryItemAction.restore,
            child: Text(context.t.settings.historyRestoreFlight),
          ),
        if (hasOfflineData)
          PopupMenuItem(
            value: _HistoryItemAction.deleteOfflineData,
            child: Text(context.t.settings.historyDeleteOfflineData),
          ),
        PopupMenuItem(
          value: _HistoryItemAction.deleteFlight,
          child: Text(context.t.home.deleteFlight),
        ),
      ];
    }

    return [
      PopupMenuItem(
        value: _HistoryItemAction.complete,
        child: Text(context.t.home.completeFlight),
      ),
      PopupMenuItem(
        value: _HistoryItemAction.deleteFlight,
        child: Text(context.t.home.deleteFlight),
      ),
    ];
  }
}

enum _HistoryItemAction { restore, complete, deleteOfflineData, deleteFlight }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final FlightStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = switch (status) {
      FlightStatus.upcoming => context.t.settings.historyStatusUpcoming,
      FlightStatus.inProgress => context.t.settings.historyStatusInProgress,
      FlightStatus.completed => context.t.settings.historyStatusCompleted,
    };
    final bg = switch (status) {
      FlightStatus.upcoming => colorScheme.secondaryContainer,
      FlightStatus.inProgress => AppColoursCommon.brandBlue.withValues(
        alpha: 0.14,
      ),
      FlightStatus.completed => colorScheme.primaryContainer,
    };
    final fg = switch (status) {
      FlightStatus.upcoming => colorScheme.onSecondaryContainer,
      FlightStatus.inProgress => AppColoursCommon.brandBlue,
      FlightStatus.completed => colorScheme.onPrimaryContainer,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.flight});

  final Flight flight;

  @override
  Widget build(BuildContext context) {
    final mapBytes = flight.maps.fold<int>(
      0,
      (sum, map) => sum + map.sizeBytes,
    );
    final label = mapBytes > 0
        ? context.t.settings.historyMapChip(
            size: SizeUtils.formatBytes(mapBytes),
          )
        : context.t.settings.historyNoMapChip;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
