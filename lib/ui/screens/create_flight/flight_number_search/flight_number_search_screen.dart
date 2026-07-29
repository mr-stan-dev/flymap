import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_flights_by_number_use_case.dart';
import 'package:flymap/domain/usecase/search_upcoming_flights_by_number_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/travel_date/travel_date_pick_screen.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';
import 'package:get_it/get_it.dart';

import '../widgets/flight_search_loading_view.dart';
import 'viewmodel/flight_number_search_cubit.dart';
import 'viewmodel/flight_number_search_state.dart';
import 'viewmodel/flight_number_validator.dart';
import 'widgets/flight_summary_card.dart';
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
      child: BlocConsumer<FlightNumberSearchCubit, FlightNumberSearchState>(
        listener: (context, state) {
          if (state is FlightNumberSearchSuccess) {
            // Flight confirmed — the date is picked on its own step next.
            AppRouter.goToTravelDatePick(
              context,
              args: TravelDatePickArgs(
                departure: state.departure,
                arrival: state.arrival,
                flightNumber: state.flightNumber,
                fr24Id: state.fr24Id,
                hasPendingFlightUnlock: widget.hasPendingFlightUnlock,
              ),
            );
          }
        },
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

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  errorText: showValidationError ? t.invalidFormatError : null,
                ),
                onChanged: (_) {
                  _hasAttemptedSearch = false;
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
                  if (canContinue) {
                    cubit.confirmSummaryAndLoadRoute(
                      flightNumber: flightNumber,
                    );
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
              if (feedback != null) feedback,
              if (singleCandidate != null) ...[
                Text(
                  t.foundTitle,
                  style: context.textTheme.title24Medium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                FlightSummaryCard(
                  summary: singleCandidate,
                  showSchedule: false,
                ),
              ] else if (candidates.isNotEmpty) ...[
                Text(
                  t.confirmTitle,
                  style: context.textTheme.title24Medium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => cubit.selectCandidate(candidate),
                      child: _SelectableFlightSummaryCard(
                        summary: candidate,
                        isSelected: selectedCandidate == candidate,
                      ),
                    );
                  },
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
                    if (!isLoading && !isError)
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: candidates.isEmpty
                              ? context.t.common.search
                              : context.t.common.kContinue,
                          onPressed: candidates.isEmpty
                              ? (canSearch ? attemptSearch : null)
                              : (canContinue
                                    ? () => cubit.confirmSummaryAndLoadRoute(
                                        flightNumber: flightNumber,
                                      )
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

class _SelectableFlightSummaryCard extends StatelessWidget {
  const _SelectableFlightSummaryCard({
    required this.summary,
    required this.isSelected,
  });

  final FlightSummary summary;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            : Colors.transparent,
      ),
      child: FlightSummaryCard(
        summary: summary,
        showBorder: false,
        showSchedule: false,
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
