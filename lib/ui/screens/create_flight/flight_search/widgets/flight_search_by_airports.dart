import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_download_completion.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/info/flight_info_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/map/flight_map_preview_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';

class FlightSearchByAirports extends StatefulWidget {
  const FlightSearchByAirports({super.key});

  @override
  State<FlightSearchByAirports> createState() => _FlightSearchByAirportsState();
}

class _FlightSearchByAirportsState extends State<FlightSearchByAirports> {
  final TextEditingController _searchController = TextEditingController();
  int _previousStepIndex = 0;
  double _stepEnterFrom = 0.0;
  bool _showDownloadSuccess = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlightSearchScreenCubit, FlightSearchScreenState>(
      listenWhen: (previous, current) {
        return previous.errorMessage != current.errorMessage ||
            previous.downloadErrorMessage != current.downloadErrorMessage ||
            previous.downloadDone != current.downloadDone ||
            previous.searchQuery != current.searchQuery ||
            previous.step != current.step;
      },
      listener: (listenerContext, state) {
        final nextStepIndex = _stepIndex(state.step);
        if (nextStepIndex != _previousStepIndex) {
          setState(() {
            _stepEnterFrom = nextStepIndex > _previousStepIndex ? 1.0 : -1.0;
            _previousStepIndex = nextStepIndex;
          });
        }

        if (_searchController.text != state.searchQuery) {
          _searchController.value = TextEditingValue(
            text: state.searchQuery,
            selection: TextSelection.collapsed(
              offset: state.searchQuery.length,
            ),
          );
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            listenerContext,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }

        if (state.downloadErrorMessage != null &&
            state.downloadErrorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            listenerContext,
          ).showSnackBar(SnackBar(content: Text(state.downloadErrorMessage!)));
        }

        if (state.downloadDone) {
          setState(() {
            _showDownloadSuccess = true;
          });
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            if (!mounted) return;
            homeRefreshNotifier.value = true;
            AppRouter.goHome(this.context);
          });
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final shouldPop = await context
                .read<FlightSearchScreenCubit>()
                .handleBackAction();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  final shouldPop = await context
                      .read<FlightSearchScreenCubit>()
                      .handleBackAction();
                  if (shouldPop && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(_titleForStep(state.step)),
            ),
            body: TweenAnimationBuilder<double>(
              key: ValueKey(state.step.name),
              tween: Tween<double>(begin: _stepEnterFrom, end: 0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(value * MediaQuery.sizeOf(context).width, 0),
                  child: child,
                );
              },
              child: _buildBody(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FlightSearchScreenState state) {
    if (_showDownloadSuccess) {
      return const FlightDownloadCompletion();
    }

    if (state.isDownloading) {
      return _buildDownloadingView(state);
    }

    switch (state.step) {
      case CreateFlightStep.departure:
      case CreateFlightStep.arrival:
        return _buildAirportSelectionStep(context, state);
      case CreateFlightStep.mapPreview:
        return _buildMapPreviewStep(context, state);
      case CreateFlightStep.overview:
        return _buildOverviewStep(context, state);
    }
  }

  Widget _buildAirportSelectionStep(
    BuildContext context,
    FlightSearchScreenState state,
  ) {
    final cubit = context.read<FlightSearchScreenCubit>();
    final theme = Theme.of(context);
    final selectedAirport = state.step == CreateFlightStep.departure
        ? state.selectedDeparture
        : state.selectedArrival;
    final favorites = _filterAirportsForCurrentStep(
      state.favoriteAirports,
      state,
    );
    final favoriteCodes = favorites.map(_airportCode).toSet();
    final popular = _filterAirportsForCurrentStep(state.popularAirports, state)
        .where((airport) => !favoriteCodes.contains(_airportCode(airport)))
        .toList();
    final results = _filterAirportsForCurrentStep(state.searchResults, state);
    final showPopularAirports = state.searchQuery.trim().isEmpty;
    const gpsActiveColor = Color(0xFF14824A);
    final borderColor = selectedAirport != null
        ? gpsActiveColor
        : theme.colorScheme.outline.withValues(alpha: 0.45);
    final focusedBorderColor = selectedAirport != null
        ? gpsActiveColor
        : theme.colorScheme.primary;

    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      if (selectedAirport != null) {
                        cubit.clearSelectedAirportForCurrentStep();
                      }
                      cubit.searchAirports(value);
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: selectedAirport != null ? gpsActiveColor : null,
                      ),
                      suffixIcon: selectedAirport != null
                          ? SizedBox(
                              width: 96,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      state.selectedAirportIsFavorite
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: state.selectedAirportIsFavorite
                                          ? Colors.amber
                                          : null,
                                    ),
                                    tooltip: state.selectedAirportIsFavorite
                                        ? 'Remove favorite'
                                        : 'Add to favorite',
                                    onPressed:
                                        cubit.toggleFavoriteForSelectedAirport,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Remove selected airport',
                                    onPressed: () {
                                      _searchController.clear();
                                      cubit
                                          .clearSelectedAirportForCurrentStep();
                                    },
                                  ),
                                ],
                              ),
                            )
                          : state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                cubit.searchAirports('');
                              },
                            )
                          : null,
                      hintText: state.step == CreateFlightStep.departure
                          ? 'Search departure airport'
                          : 'Search arrival airport',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: borderColor,
                          width: selectedAirport != null ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: focusedBorderColor,
                          width: selectedAirport != null ? 2.4 : 1.8,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.isSearchLoading && selectedAirport == null)
                    const Center(child: CircularProgressIndicator())
                  else if (state.searchQuery.isNotEmpty &&
                      results.isEmpty &&
                      selectedAirport == null)
                    _EmptySearchResults(step: state.step)
                  else if (results.isNotEmpty && selectedAirport == null)
                    _SearchResultList(
                      airports: results,
                      onSelectAirport: cubit.selectAirport,
                    ),
                  if (favorites.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Favorites',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AirportChipWrap(
                      airports: favorites,
                      onSelectAirport: cubit.selectAirport,
                      showFavoriteTrailingIcon: true,
                      onToggleFavorite: cubit.toggleFavoriteForAirport,
                    ),
                  ],
                  if (showPopularAirports) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Popular airports',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AirportChipWrap(
                      airports: popular,
                      onSelectAirport: cubit.selectAirport,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: selectedAirport == null
                        ? null
                        : () => cubit.continueFromAirportStep(),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreviewStep(
    BuildContext context,
    FlightSearchScreenState state,
  ) {
    final route = state.flightRoute;
    if (state.isPreviewLoading || route == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: FlightMapPreviewWidget(
            flightRoute: route,
            flightInfo: state.flightInfo,
          ),
        ),
        if (state.isTooLongFlight)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Downloading routes over 5,000 km is not supported yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: state.canContinueFromMap
                    ? () => context
                          .read<FlightSearchScreenCubit>()
                          .continueFromMap()
                    : null,
                child: const Text('Continue'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStep(
    BuildContext context,
    FlightSearchScreenState state,
  ) {
    final route = state.flightRoute;
    if (route == null) {
      return const Center(child: Text('Route is not ready yet.'));
    }

    final isDownloadEnabled = !state.isTooLongFlight;
    final buttonText = state.isTooLongFlight
        ? 'Too long flight (> 5000km)'
        : 'Download map';

    return Column(
      children: [
        Expanded(
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isOverviewLoading) ...[
                    Row(
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Building route overview...'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  FlightInfoWidget(route: route, info: state.flightInfo),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: isDownloadEnabled
                    ? () => context
                          .read<FlightSearchScreenCubit>()
                          .startDownload()
                    : null,
                child: Text(buttonText),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadingView(FlightSearchScreenState state) {
    final percent = (state.downloadProgress * 100).clamp(0, 100).toInt();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Downloading offline map...',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: state.downloadProgress),
            const SizedBox(height: 8),
            Text('$percent%'),
            const SizedBox(height: 4),
            Text(
              'Downloaded: ${_formatDownloadedMb(state.downloadedBytes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.read<FlightSearchScreenCubit>().cancelDownload(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel download'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForStep(CreateFlightStep step) {
    switch (step) {
      case CreateFlightStep.departure:
        return 'Choose departure airport';
      case CreateFlightStep.arrival:
        return 'Choose arrival airport';
      case CreateFlightStep.mapPreview:
        return 'Map preview';
      case CreateFlightStep.overview:
        return 'Route overview';
    }
  }

  int _stepIndex(CreateFlightStep step) {
    switch (step) {
      case CreateFlightStep.departure:
        return 0;
      case CreateFlightStep.arrival:
        return 1;
      case CreateFlightStep.mapPreview:
        return 2;
      case CreateFlightStep.overview:
        return 3;
    }
  }

  String _formatDownloadedMb(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  List<Airport> _filterAirportsForCurrentStep(
    List<Airport> airports,
    FlightSearchScreenState state,
  ) {
    if (state.step != CreateFlightStep.arrival) return airports;
    final departureCode = _airportCode(state.selectedDeparture);
    if (departureCode.isEmpty) return airports;
    return airports
        .where((airport) => _airportCode(airport) != departureCode)
        .toList();
  }

  String _airportCode(Airport? airport) {
    if (airport == null) return '';
    final primary = airport.primaryCode.trim().toUpperCase();
    if (primary.isNotEmpty) return primary;
    return airport.displayCode.trim().toUpperCase();
  }
}

class _AirportChipWrap extends StatelessWidget {
  const _AirportChipWrap({
    required this.airports,
    required this.onSelectAirport,
    this.showFavoriteTrailingIcon = false,
    this.onToggleFavorite,
  });

  final List<Airport> airports;
  final Future<void> Function(Airport airport) onSelectAirport;
  final bool showFavoriteTrailingIcon;
  final Future<void> Function(Airport airport)? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: airports.map((airport) {
        return InputChip(
          label: Text('${airport.displayCode} · ${airport.city}'),
          selected: false,
          onPressed: () => onSelectAirport(airport),
          onDeleted: showFavoriteTrailingIcon && onToggleFavorite != null
              ? () => onToggleFavorite!(airport)
              : null,
          deleteIcon: showFavoriteTrailingIcon
              ? const Icon(Icons.star, color: Colors.amber, size: 18)
              : null,
          deleteButtonTooltipMessage: showFavoriteTrailingIcon
              ? 'Remove from favorites'
              : null,
        );
      }).toList(),
    );
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
            '${airport.name} (${airport.displayCode})',
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

  final CreateFlightStep step;

  @override
  Widget build(BuildContext context) {
    final text = step == CreateFlightStep.departure
        ? 'No departure airports found.'
        : 'No arrival airports found.';
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
