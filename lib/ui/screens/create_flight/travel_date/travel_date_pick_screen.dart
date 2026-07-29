import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';
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
    this.hasPendingFlightUnlock = false,
  });

  final Airport departure;
  final Airport arrival;
  final String? flightNumber;
  final String? fr24Id;
  final bool hasPendingFlightUnlock;
}

/// Dedicated "When are you flying?" step, shared by all create-flight flows.
///
/// Real flights are Flighty-style: the user picks ONE date, which is
/// verified against the provider for that exact day — a match silently
/// attaches the real departure schedule; a miss stays an honest date-only
/// pick with an optional manual time (converted through the airport's
/// timezone). No schedule browsing, no guessed day lists. Approximate
/// flights get a generic Today..+6 calendar grid instead. Both end with the
/// dateless escape hatch — a date is never required.
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

  /// Approximate flights only: the generic Today..+6 calendar.
  List<_DateOption> _options = const [];
  int? _selectedIndex;
  DateTime? _customDate;
  TimeOfDay? _customTime;
  bool _customSelected = false;

  /// Flighty-style exact-date check: a picked date is verified against the
  /// provider for that day, so it carries a real departure time whenever
  /// one exists.
  bool _customVerifying = false;
  bool _customChecked = false;
  bool _customCheckFailed = false;
  _DateOption? _customVerifiedOption;
  AirportTimezoneService? _timezoneService;

  /// Manual TIME entry is offered only when the departure airport's timezone
  /// is known — a wall-clock time without a timezone would be a guess.
  bool _departureTzKnown = false;

  bool get _isRealFlight => widget.args.flightNumber != null;

  @override
  void initState() {
    super.initState();
    if (!_isRealFlight) {
      final today = _today();
      _options = List.generate(
        _windowDays,
        (index) => _DateOption(
          schedule: FlightSchedule.dateOnly(today.add(Duration(days: index))),
        ),
      );
    }
    _initTimezoneService();
    // No preselection on purpose: the date is real data, so it must be an
    // explicit choice — Continue stays disabled until one is made, and the
    // dateless escape hatch covers everyone else.
  }

  Future<void> _initTimezoneService() async {
    if (!_isRealFlight) return;
    // Guarded for widget tests without DI.
    if (!GetIt.I.isRegistered<AirportTimezoneService>()) return;
    final service = GetIt.I.get<AirportTimezoneService>();
    await service.ensureReady();
    if (!mounted) return;
    setState(() {
      _timezoneService = service;
      _departureTzKnown =
          service.localTimeToUtc(widget.args.departure, DateTime.now()) !=
          null;
    });
  }

  /// Checks the provider for departures on exactly [date]; a match attaches
  /// the real schedule silently, a miss stays honest date-only.
  Future<void> _verifyCustomDate(DateTime date) async {
    final flightNumber = widget.args.flightNumber;
    if (flightNumber == null) return;
    // Guarded for widget tests without DI.
    if (!GetIt.I.isRegistered<SearchUpcomingFlightsByNumberUseCase>()) return;
    setState(() => _customVerifying = true);
    List<FlightSummary> found = const [];
    var failed = false;
    try {
      found = await GetIt.I
          .get<SearchUpcomingFlightsByNumberUseCase>()
          .call(flightNumber, date: date);
      _logScheduleLookup(
        found.isEmpty
            ? FlightNumberLookupResult.notFound
            : FlightNumberLookupResult.success,
      );
    } catch (error, stackTrace) {
      final result = flightNumberLookupResultFromError(error);
      _logScheduleLookup(result);
      if (result.isProviderFailure) {
        failed = true;
        if (GetIt.I.isRegistered<AppCrashlytics>()) {
          unawaited(
            GetIt.I.get<AppCrashlytics>().recordError(
              error,
              stackTrace,
              reason: 'schedule_lookup_date_${result.analyticsValue}',
            ),
          );
        }
      }
    }
    // Ignore stale results if the user picked another date meanwhile.
    if (!mounted || _customDate != date) return;
    final matches = [
      for (final summary in _filterToRoute(found))
        if (summary.schedule?.departure != null)
          _DateOption(schedule: summary.schedule!, fr24Id: summary.fr24Id),
    ];
    setState(() {
      _customVerifying = false;
      _customChecked = !failed;
      _customCheckFailed = failed;
      _customVerifiedOption = matches.isEmpty ? null : matches.first;
    });
  }

  void _logScheduleLookup(FlightNumberLookupResult result) {
    // Guarded for widget tests without DI.
    if (!GetIt.I.isRegistered<AppAnalytics>()) return;
    unawaited(
      GetIt.I.get<AppAnalytics>().log(
        ScheduleLookupResultEvent(
          result: result,
          source: ScheduleLookupSource.travelDateStep,
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

  /// Approximate flights: a compact two-column Today..+6 grid (a calendar,
  /// not a schedule claim) plus the custom row. Real flights: just the
  /// pick-a-date entry — the date is verified, never browsed.
  Widget _buildOptionsList() {
    final dateT = context.t.createFlight.travelDate;

    if (_isRealFlight) {
      final today = _today();
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          _quickDateRow(dateT.today, today),
          const SizedBox(height: 10),
          _quickDateRow(dateT.tomorrow, today.add(const Duration(days: 1))),
          const SizedBox(height: 10),
          ..._customEntryWidgets(dateT),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.0,
          children: [
            for (var i = 0; i < _options.length; i++)
              _DateOptionRow(
                icon: Icons.event_rounded,
                label: _optionLabel(_options[i]),
                isSelected: !_customSelected && _selectedIndex == i,
                compact: true,
                onTap: () => setState(() {
                  _selectedIndex = i;
                  _customSelected = false;
                }),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ..._customEntryWidgets(dateT),
      ],
    );
  }

  /// Real-flight quick pick: Today / Tomorrow as one-tap rows, verified on
  /// selection exactly like a calendar pick.
  Widget _quickDateRow(String label, DateTime date) {
    final selected = _customSelected && _customDate == date;
    return _DateOptionRow(
      icon: Icons.event_rounded,
      label: '$label${_verifiedTimeSuffix(date)}',
      isSelected: selected,
      onTap: () => _selectDate(date),
    );
  }

  /// " · 16:10" once the row's date is selected and verified; " · …" while
  /// the check runs.
  String _verifiedTimeSuffix(DateTime date) {
    if (!(_customSelected && _customDate == date)) return '';
    if (_customVerifying) return ' · …';
    final local = _customVerifiedOption?.schedule.departureLocal;
    if (local == null) return '';
    return ' · ${TravelDateFormatUtils.formatTime(local)}';
  }

  bool _isQuickDate(DateTime date) {
    final today = _today();
    return date == today || date == today.add(const Duration(days: 1));
  }

  /// The calendar row plus its satellites: the prominent verify-outcome
  /// message (didn't find the flight that day / check failed, with an
  /// edit-the-date pointer) and the low-key manual-time fallback.
  List<Widget> _customEntryWidgets(dynamic dateT) {
    final theme = Theme.of(context);
    final verified = _customVerifiedOption;

    // Today/Tomorrow selections are owned by the quick rows above — the
    // calendar row then stays in its idle state.
    final ownsSelection =
        _customSelected &&
        _customDate != null &&
        (!_isRealFlight || !_isQuickDate(_customDate!));
    final String label;
    if (!ownsSelection || _customDate == null) {
      label = _isRealFlight ? dateT.pickDate : dateT.customDate;
    } else {
      label =
          TravelDateFormatUtils.formatShortDate(_customDate!) +
          (_isRealFlight ? _verifiedTimeSuffix(_customDate!) : '');
    }

    final showMessage =
        _isRealFlight &&
        _customSelected &&
        !_customVerifying &&
        verified == null &&
        (_customChecked || _customCheckFailed);
    final showTimeFallback =
        _isRealFlight &&
        _customSelected &&
        _customDate != null &&
        _departureTzKnown &&
        !_customVerifying &&
        verified == null;
    return [
      _DateOptionRow(
        icon: Icons.calendar_month_rounded,
        label: label,
        isSelected: ownsSelection,
        onTap: _pickCustomDate,
      ),
      if (showMessage) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _customCheckFailed
                    ? dateT.dateCheckFailed
                    : dateT.noDepartureOnDateTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateT.noDepartureOnDateBody,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
      if (showTimeFallback) ...[
        const SizedBox(height: 4),
        // A hatch, not a headline — same weight as "continue without a
        // date" below.
        Align(
          alignment: Alignment.centerLeft,
          child: TertiaryButton(
            label: _customTime == null
                ? dateT.addDepartureTime
                : dateT.departureTimeAt(time: _formatTime(_customTime!)),
            onPressed: _pickCustomTime,
            expand: false,
          ),
        ),
      ],
    ];
  }

  String _formatTime(TimeOfDay time) {
    return TravelDateFormatUtils.formatTime(
      DateTime(2000, 1, 1, time.hour, time.minute),
    );
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
    final departureLocal = schedule.departureLocal;
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
    _selectDate(DateTime(picked.year, picked.month, picked.day));
  }

  /// Selects a date (quick row or calendar) and kicks off verification.
  void _selectDate(DateTime date) {
    setState(() {
      _customDate = date;
      _customSelected = true;
      _selectedIndex = null;
      _customTime = null;
      _customVerifiedOption = null;
      _customChecked = false;
      _customCheckFailed = false;
    });
    unawaited(_verifyCustomDate(date));
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _customTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _customTime = picked);
  }

  /// Manual date (+ optional time): the time is wall-clock at the departure
  /// airport, converted to a real [ZonedInstant] through the airport's
  /// timezone — same shape as a provider schedule, so weather and reminders
  /// work identically.
  FlightSchedule _manualSchedule(DateTime date) {
    final time = _customTime;
    final service = _timezoneService;
    if (time == null || service == null || !_isRealFlight) {
      return FlightSchedule.dateOnly(date);
    }
    final utc = service.localTimeToUtc(
      widget.args.departure,
      date,
      hour: time.hour,
      minute: time.minute,
    );
    if (utc == null) return FlightSchedule.dateOnly(date);
    return FlightSchedule(
      travelDate: DateTime(date.year, date.month, date.day),
      departure: ZonedInstant(
        utc: utc,
        offsetMinutes: service.utcOffsetMinutes(widget.args.departure, utc),
      ),
    );
  }

  void _continue({required bool withoutDate}) {
    FlightSchedule? schedule;
    String? fr24Id = widget.args.fr24Id;
    if (!withoutDate) {
      if (_customSelected && _customDate != null) {
        final verified = _customVerifiedOption;
        if (verified != null) {
          // Provider-confirmed departure for the picked day: real schedule.
          schedule = verified.schedule;
          fr24Id = verified.fr24Id ?? fr24Id;
        } else {
          schedule = _manualSchedule(_customDate!);
        }
      } else if (_selectedIndex != null) {
        schedule = _options[_selectedIndex!].schedule;
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
        !_customVerifying && (_selectedIndex != null || _customSelected);
    // The freshness hint is only relevant once a date is chosen AND it is
    // actually far out — "flying later?" is noise before that.
    final selectedDate = _customSelected
        ? _customDate
        : _selectedIndex != null
        ? _options[_selectedIndex!].schedule.travelDate
        : null;
    final showFreshnessHint =
        selectedDate != null && selectedDate.difference(_today()).inDays > 7;

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
              Expanded(child: _buildOptionsList()),
              if (showFreshnessHint) ...[
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
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Grid-cell variant: tighter padding, no trailing radio — selection is
  /// carried by the border/fill alone.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 10 : 14,
        ),
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
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (!compact)
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
