import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_upcoming_flights_by_number_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';
import 'package:get_it/get_it.dart';

class TravelDatePickArgs {
  const TravelDatePickArgs({
    required this.departure,
    required this.arrival,
    this.flightNumber,
    this.fr24Id,
    this.scheduleOptions,
    this.hasPendingFlightUnlock = false,
  });

  final Airport departure;
  final Airport arrival;
  final String? flightNumber;
  final String? fr24Id;

  /// Dated departures already fetched by the previous step. Null means
  /// "fetch here" (airport-pair flow); an empty list means "known dateless"
  /// (historical fallback) — both degrade to the generic day list.
  final List<FlightSummary>? scheduleOptions;
  final bool hasPendingFlightUnlock;
}

/// Dedicated "When are you flying?" step, shared by all create-flight flows.
///
/// Real flights show the picked flight's actual departure days (with times);
/// approximate and dateless flights get a generic Today..+6 list. Both end
/// with a custom-date row and a dateless escape hatch — a date is never
/// required.
class TravelDatePickScreen extends StatefulWidget {
  const TravelDatePickScreen({required this.args, super.key});

  final TravelDatePickArgs args;

  @override
  State<TravelDatePickScreen> createState() => _TravelDatePickScreenState();
}

class _DateOption {
  const _DateOption({required this.schedule, this.fr24Id});

  final FlightSchedule schedule;

  /// Recorded leg stitched to this specific departure, when available.
  final String? fr24Id;
}

class _TravelDatePickScreenState extends State<TravelDatePickScreen> {
  static const int _windowDays = 7;

  bool _isLoading = false;
  List<_DateOption> _options = const [];
  int? _selectedIndex;
  DateTime? _customDate;
  bool _customSelected = false;

  bool get _isRealFlight => widget.args.flightNumber != null;

  @override
  void initState() {
    super.initState();
    final provided = widget.args.scheduleOptions;
    if (provided != null) {
      _options = _buildOptions(provided);
    } else if (_isRealFlight) {
      _fetchSchedule();
    } else {
      _options = _buildOptions(const []);
    }
    // No preselection on purpose: the date is real data, so it must be an
    // explicit choice — Continue stays disabled until one is made, and the
    // dateless escape hatch covers everyone else.
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    List<FlightSummary> upcoming = const [];
    try {
      upcoming = await GetIt.I
          .get<SearchUpcomingFlightsByNumberUseCase>()
          .call(widget.args.flightNumber!);
    } catch (_) {
      // Schedule unavailable — the generic day list below still works.
    }
    if (!mounted) return;
    final options = _buildOptions(_filterToRoute(upcoming));
    setState(() {
      _isLoading = false;
      _options = options.isNotEmpty ? options : _buildOptions(const []);
    });
  }

  /// Scheduled departures when available; otherwise a plain Today..+6 list.
  List<_DateOption> _buildOptions(List<FlightSummary> summaries) {
    final scheduled = summaries
        .where((summary) => summary.schedule != null)
        .map(
          (summary) =>
              _DateOption(schedule: summary.schedule!, fr24Id: summary.fr24Id),
        )
        .toList();
    if (scheduled.isNotEmpty) return scheduled;

    final today = _today();
    return List.generate(
      _windowDays,
      (index) => _DateOption(
        schedule: FlightSchedule.dateOnly(
          today.add(Duration(days: index)),
        ),
      ),
    );
  }

  /// Keeps only departures on the picked airport pair; if the number serves
  /// other pairs only, keeps everything rather than showing nothing.
  List<FlightSummary> _filterToRoute(List<FlightSummary> summaries) {
    final departureCodes = _airportCodes(widget.args.departure);
    final arrivalCodes = _airportCodes(widget.args.arrival);
    if (departureCodes.isEmpty || arrivalCodes.isEmpty) return summaries;
    final samePair = summaries.where((summary) {
      final origCodes = {
        if (summary.origIcao != null) summary.origIcao!.toUpperCase(),
        if (summary.departure != null) ..._airportCodes(summary.departure!),
      };
      final destCodes = {
        if (summary.destIcao != null) summary.destIcao!.toUpperCase(),
        if (summary.arrival != null) ..._airportCodes(summary.arrival!),
      };
      return origCodes.intersection(departureCodes).isNotEmpty &&
          destCodes.intersection(arrivalCodes).isNotEmpty;
    }).toList();
    return samePair.isNotEmpty ? samePair : summaries;
  }

  Set<String> _airportCodes(Airport airport) {
    return {
      if (airport.iataCode.trim().isNotEmpty)
        airport.iataCode.trim().toUpperCase(),
      if (airport.icaoCode.trim().isNotEmpty)
        airport.icaoCode.trim().toUpperCase(),
    };
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _optionLabel(_DateOption option) {
    final schedule = option.schedule;
    final daysAway = schedule.travelDate.difference(_today()).inDays;
    final dateT = context.t.createFlight.travelDate;
    final dayLabel = switch (daysAway) {
      0 => dateT.today,
      1 => dateT.tomorrow,
      _ => TravelDateFormatUtils.formatShortDate(schedule.travelDate),
    };
    final departureLocal = schedule.scheduledDepartureLocal;
    if (departureLocal == null) return dayLabel;
    return '$dayLabel · ${TravelDateFormatUtils.formatTime(departureLocal)}';
  }

  Future<void> _pickCustomDate() async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customDate = DateTime(picked.year, picked.month, picked.day);
      _customSelected = true;
      _selectedIndex = null;
    });
  }

  void _continue({required bool withoutDate}) {
    FlightSchedule? schedule;
    String? fr24Id = widget.args.fr24Id;
    if (!withoutDate) {
      if (_customSelected && _customDate != null) {
        schedule = FlightSchedule.dateOnly(_customDate!);
      } else if (_selectedIndex != null) {
        final option = _options[_selectedIndex!];
        schedule = option.schedule;
        fr24Id = option.fr24Id ?? fr24Id;
      }
    }
    AppRouter.goToFlightOverview(
      context,
      departure: widget.args.departure,
      arrival: widget.args.arrival,
      flightNumber: widget.args.flightNumber,
      fr24Id: fr24Id,
      schedule: schedule,
      hasPendingFlightUnlock: widget.args.hasPendingFlightUnlock,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateT = context.t.createFlight.travelDate;
    final theme = Theme.of(context);
    final routeLabel = [
      '${widget.args.departure.displayCode} → '
          '${widget.args.arrival.displayCode}',
      if (widget.args.flightNumber != null) widget.args.flightNumber!,
    ].join(' · ');
    final canContinue =
        !_isLoading && (_selectedIndex != null || _customSelected);

    return Scaffold(
      appBar: AppBar(title: Text(context.t.home.newFlight)),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateT.stepTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                routeLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _options.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index < _options.length) {
                            final option = _options[index];
                            return _DateOptionRow(
                              icon: Icons.event_rounded,
                              label: _optionLabel(option),
                              isSelected:
                                  !_customSelected && _selectedIndex == index,
                              onTap: () => setState(() {
                                _selectedIndex = index;
                                _customSelected = false;
                              }),
                            );
                          }
                          return _DateOptionRow(
                            icon: Icons.calendar_month_rounded,
                            label: _customDate == null
                                ? dateT.customDate
                                : TravelDateFormatUtils.formatShortDate(
                                    _customDate!,
                                  ),
                            isSelected: _customSelected,
                            onTap: _pickCustomDate,
                          );
                        },
                      ),
              ),
              if (_isRealFlight) ...[
                const SizedBox(height: 12),
                Text(
                  context.t.createFlight.flightNumberSearch.beyondWindowHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TertiaryButton(
                  label: dateT.skipDate,
                  onPressed: () => _continue(withoutDate: true),
                  expand: false,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: context.t.common.kContinue,
                  onPressed: canContinue
                      ? () => _continue(withoutDate: false)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateOptionRow extends StatelessWidget {
  const _DateOptionRow({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
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
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
