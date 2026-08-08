import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_flights_by_number_use_case.dart';
import 'package:flymap/domain/usecase/search_upcoming_flights_by_number_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/travel_date/flight_notification_permission_prompt.dart';
import 'package:flymap/ui/screens/create_flight/travel_date/travel_date_section.dart';
import 'package:flymap/ui/screens/create_flight/widgets/compact_flight_strip.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';
import 'package:get_it/get_it.dart';

import '../widgets/flight_search_loading_view.dart';
import 'viewmodel/flight_number_search_cubit.dart';
import 'viewmodel/flight_number_search_state.dart';
import 'viewmodel/flight_number_validator.dart';
import 'widgets/search_fallback_action.dart';

class FlightNumberSearchScreen extends StatefulWidget {
  const FlightNumberSearchScreen({
    this.hasPendingFlightUnlock = false,
    super.key,
  });

  final bool hasPendingFlightUnlock;

  @override
  State<FlightNumberSearchScreen> createState() =>
      _FlightNumberSearchScreenState();
}

class _FlightNumberSearchScreenState extends State<FlightNumberSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  /// Validation feedback only appears after a search attempt — flagging
  /// "LH1114" as invalid while the user is still on "LH1" is just noise.
  bool _hasAttemptedSearch = false;

  /// The inline date section's current choice (null = no date yet) and
  /// whether its exact-day verification is still running.
  TravelDateSelection? _dateSelection;
  bool _dateBusy = false;

  Future<void> _continueToOverview(FlightSummary candidate) async {
    final departure = candidate.departure;
    final arrival = candidate.arrival;
    if (departure == null || arrival == null) return;
    final number = (candidate.flightNumber ?? _controller.text)
        .replaceAll(RegExp(r'\s+'), '')
        .trim()
        .toUpperCase();
    final schedule = _dateSelection?.schedule;
    if (schedule != null) {
      final shouldContinue =
          await FlightNotificationPermissionPrompt.showIfEligible(
            context: context,
            schedule: schedule,
            departure: departure,
          );
      if (!mounted || !shouldContinue) return;
    }
    AppRouter.goToFlightOverview(
      context,
      departure: departure,
      arrival: arrival,
      flightNumber: number,
      fr24Id: _dateSelection?.fr24Id ?? candidate.fr24Id,
      airlineCodeHint: candidate.airlineCode,
      airlineNameHint: candidate.airlineName,
      schedule: schedule,
      hasPendingFlightUnlock: widget.hasPendingFlightUnlock,
    );
  }

  void _goToAirportSearch() {
    AppRouter.goToRealRouteAirportSearch(
      context,
      hasPendingFlightUnlock: widget.hasPendingFlightUnlock,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlightNumberSearchCubit(
        searchFlightsByNumberUseCase: GetIt.I
            .get<SearchFlightsByNumberUseCase>(),
        searchUpcomingFlightsByNumberUseCase: GetIt.I
            .get<SearchUpcomingFlightsByNumberUseCase>(),
        analytics: GetIt.I.get(),
        crashlytics: GetIt.I.get(),
      ),
      child: BlocBuilder<FlightNumberSearchCubit, FlightNumberSearchState>(
        builder: (context, state) {
          final cubit = context.read<FlightNumberSearchCubit>();
          final isLoading = state is FlightNumberSearchLoading;
          final resultsState = state is FlightNumberSearchResultsLoaded
              ? state
              : null;
          final errorState = state is FlightNumberSearchError ? state : null;
          final isError = errorState != null;
          final candidates =
              resultsState?.candidates ??
              errorState?.candidates ??
              const <FlightSummary>[];
          final selectedCandidate =
              resultsState?.selectedCandidate ?? errorState?.selectedCandidate;
          final singleCandidate = candidates.length == 1
              ? candidates.single
              : null;
          final showInitialFindByAirports =
              state is FlightNumberSearchInitial && !isLoading;

          final flightNumber = _controller.text.trim();
          final hasInput = flightNumber.isNotEmpty;
          final isFlightNumberValid = FlightNumberValidator.isValid(
            flightNumber,
          );
          final canSearch = hasInput && !isLoading;
          final canContinue =
              candidates.isNotEmpty && selectedCandidate != null && !isLoading;
          final showValidationError =
              _hasAttemptedSearch &&
              hasInput &&
              !isFlightNumberValid &&
              candidates.isEmpty &&
              !isError;

          void attemptSearch() {
            if (!canSearch) return;
            if (!isFlightNumberValid) {
              setState(() => _hasAttemptedSearch = true);
              return;
            }
            cubit.loadFlightSummary(flightNumber);
          }

          final t = context.t.createFlight.flightNumberSearch;

          Widget? feedback;
          if (isLoading) {
            feedback = FlightSearchLoadingView(
              stages: [t.loading, t.loadingHint],
              cardCount: 2,
            );
          } else if (isError) {
            // Transient failures lead with Retry; not-found leads with the
            // airports fallback (retrying the same number cannot help).
            feedback = Padding(
              padding: const EdgeInsets.only(top: 16),
              child: errorState.isRetryable
                  ? SearchFallbackAction(
                      icon: Icons.cloud_off_rounded,
                      message: errorState.message,
                      actionLabel: context.t.common.retry,
                      onPressed: () => cubit.loadFlightSummary(flightNumber),
                      secondaryActionLabel: t.airportsFallbackButton,
                      onSecondaryPressed: _goToAirportSearch,
                    )
                  : SearchFallbackAction(
                      icon: Icons.travel_explore_rounded,
                      message: errorState.message,
                      actionLabel: t.airportsFallbackButton,
                      onPressed: _goToAirportSearch,
                    ),
            );
          }

          void resetToSearch() {
            setState(() {
              _dateSelection = null;
              _dateBusy = false;
            });
            cubit.clearSummary();
          }

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Once a flight is found, the search header collapses — the
              // results title carries an edit action instead.
              if (candidates.isEmpty) ...[
                Text(t.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(t.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: t.hint,
                    border: const OutlineInputBorder(),
                    errorText: showValidationError
                        ? t.invalidFormatError
                        : null,
                  ),
                  onChanged: (_) {
                    _hasAttemptedSearch = false;
                    _dateSelection = null;
                    _dateBusy = false;
                    if (candidates.isNotEmpty || isError) {
                      cubit.clearSummary();
                    } else {
                      setState(() {});
                    }
                  },
                  onSubmitted: (_) {
                    if (candidates.isEmpty) {
                      attemptSearch();
                      return;
                    }
                    if (canContinue && !_dateBusy) {
                      _continueToOverview(selectedCandidate);
                    }
                  },
                ),
                if (showInitialFindByAirports) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TertiaryButton(
                      label: t.findByAirports,
                      onPressed: _goToAirportSearch,
                      expand: false,
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 24),
              ],
              if (feedback != null) feedback,
              // Compact identity strips keep the date question above the
              // fold; the full card is the reveal AFTER a date is verified
              // (inside the date section).
              if (singleCandidate != null && !_dateBusy) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.foundTitle,
                        style: context.textTheme.title24Medium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: resetToSearch,
                      tooltip: t.editFlightNumber,
                      icon: const Icon(Icons.edit_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // The identity strip renders inside the date section, so
                // it can hide while verifying and become the full card.
              ] else if (candidates.isNotEmpty &&
                  _dateSelection == null &&
                  !_dateBusy) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.confirmTitle,
                        style: context.textTheme.title24Medium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: resetToSearch,
                      tooltip: t.editFlightNumber,
                      icon: const Icon(Icons.edit_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    final isSelected = selectedCandidate == candidate;
                    return CompactFlightStrip(
                      summary: candidate,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _dateSelection = null;
                          _dateBusy = false;
                        });
                        cubit.selectCandidate(candidate);
                      },
                      trailing: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
              if (!isLoading &&
                  !isError &&
                  selectedCandidate != null &&
                  selectedCandidate.departure != null &&
                  selectedCandidate.arrival != null) ...[
                const SizedBox(height: 20),
                TravelDateSection(
                  key: ValueKey(
                    FlightNumberSearchCubit.candidateGroupKey(
                      selectedCandidate,
                    ),
                  ),
                  departure: selectedCandidate.departure!,
                  arrival: selectedCandidate.arrival!,
                  flightNumber: selectedCandidate.flightNumber ?? flightNumber,
                  confirmedFlight: selectedCandidate,
                  // With several candidates the selection list above is the
                  // identity in the idle state.
                  showIdleStrip: singleCandidate != null,
                  onSelectionChanged: (selection) =>
                      setState(() => _dateSelection = selection),
                  onBusyChanged: (busy) => setState(() => _dateBusy = busy),
                ),
              ],
            ],
          );

          return Scaffold(
            appBar: AppBar(title: Text(context.t.home.newFlight)),
            body: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(child: SingleChildScrollView(child: content)),
                    const SizedBox(height: 16),
                    if (!isLoading && !isError)
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: candidates.isEmpty
                              ? context.t.common.search
                              // Dateless is its own chip now — Continue
                              // stays disabled until an explicit choice.
                              : _dateSelection != null &&
                                    _dateSelection!.schedule == null
                              ? context.t.createFlight.travelDate.skipDate
                              : context.t.common.kContinue,
                          onPressed: candidates.isEmpty
                              ? (canSearch ? attemptSearch : null)
                              : ((canContinue &&
                                        !_dateBusy &&
                                        _dateSelection != null)
                                    ? () =>
                                          _continueToOverview(selectedCandidate)
                                    : null),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
