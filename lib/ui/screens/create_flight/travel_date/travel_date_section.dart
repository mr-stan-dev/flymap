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
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_number_search/widgets/flight_summary_card.dart';
import 'package:flymap/ui/screens/create_flight/widgets/compact_flight_strip.dart';
import 'package:flymap/ui/screens/settings/date_display_format_context.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';
import 'package:get_it/get_it.dart';

/// What the user chose on the date section. [schedule] is null for the
/// EXPLICIT "no date yet" choice; otherwise at least a calendar date,
/// upgraded to the provider-verified schedule when the exact-day check
/// found the flight (then [fr24Id] carries the dated leg's recording).
/// The host's Continue stays disabled until a selection exists — skipping
/// the date is a conscious tap, never a default.
class TravelDateSelection {
  const TravelDateSelection({required this.schedule, this.fr24Id});

  final FlightSchedule? schedule;
  final String? fr24Id;
}

/// Inline "When are you flying?" for REAL flights, embedded right under the
/// found-flight strip on the search screens (no separate date screen).
///
/// Two-state machine: IDLE (Today / Tomorrow / pick a date chips) and
/// PICKED (loading -> the full confirmed flight card, or the honest miss
/// panel with its fallbacks) with a "change date" way back. Every picked
/// date is verified against the provider for that exact day; identity
/// always comes from [confirmedFlight] — a sparse schedule entry can never
/// degrade what is shown.
class TravelDateSection extends StatefulWidget {
  const TravelDateSection({
    required this.departure,
    required this.arrival,
    required this.flightNumber,
    required this.onSelectionChanged,
    required this.onBusyChanged,
    this.confirmedFlight,
    this.showIdleStrip = true,
    this.stripShowRoute = true,
    this.onStripTap,
    this.stripTrailing,
    super.key,
  });

  final Airport departure;
  final Airport arrival;
  final String flightNumber;

  /// The exact card the user confirmed — the flight's identity. The
  /// verified entry only contributes schedule fields. Rendered by the
  /// section itself as a compact strip (idle/miss), replaced by the full
  /// card on a verified date, hidden while verifying.
  final FlightSummary? confirmedFlight;

  /// Off when the host screen shows its own selection list in the idle
  /// state (multi-candidate flows) — the strip would be a duplicate. The
  /// miss state always shows the strip (the list is hidden by then).
  final bool showIdleStrip;

  /// Off in the airport-pair flow, where the route is in the header.
  final bool stripShowRoute;

  /// e.g. "back to the flight list" in the airport-pair flow.
  final VoidCallback? onStripTap;
  final Widget? stripTrailing;

  /// Fired with the current choice: null = no date picked; date-only
  /// immediately on pick; upgraded to the verified schedule when found.
  final ValueChanged<TravelDateSelection?> onSelectionChanged;

  /// True while the exact-day verification runs — disable Continue.
  final ValueChanged<bool> onBusyChanged;

  @override
  State<TravelDateSection> createState() => _TravelDateSectionState();
}

class _TravelDateSectionState extends State<TravelDateSection> {
  DateTime? _date;

  /// Explicit "no date yet" choice (its own chip — never a default).
  bool _datelessChosen = false;
  TimeOfDay? _time;
  bool _verifying = false;
  bool _checked = false;
  bool _checkFailed = false;
  FlightSummary? _verifiedSummary;
  TravelDateSelection? _verifiedSelection;
  AirportTimezoneService? _timezoneService;

  /// Manual TIME entry is offered only when the departure airport's
  /// timezone is known — a wall-clock time without one would be a guess.
  bool _departureTzKnown = false;

  @override
  void initState() {
    super.initState();
    _initTimezoneService();
  }

  Future<void> _initTimezoneService() async {
    // Guarded for widget tests without DI.
    if (!GetIt.I.isRegistered<AirportTimezoneService>()) return;
    final service = GetIt.I.get<AirportTimezoneService>();
    await service.ensureReady();
    if (!mounted) return;
    setState(() {
      _timezoneService = service;
      _departureTzKnown =
          service.localTimeToUtc(widget.departure, DateTime.now()) != null;
    });
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _selectDateless() {
    setState(() {
      _datelessChosen = true;
      _date = null;
      _time = null;
      _verifiedSummary = null;
      _verifiedSelection = null;
      _checked = false;
      _checkFailed = false;
    });
    widget.onSelectionChanged(const TravelDateSelection(schedule: null));
  }

  void _selectDate(DateTime date) {
    setState(() {
      _datelessChosen = false;
      _date = date;
      _time = null;
      _verifiedSummary = null;
      _verifiedSelection = null;
      _checked = false;
      _checkFailed = false;
    });
    // A picked date is at least a date-only schedule from the first moment.
    widget.onSelectionChanged(
      TravelDateSelection(schedule: FlightSchedule.dateOnly(date)),
    );
    unawaited(_verifyDate(date));
  }

  Future<void> _pickCustomDate() async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    _selectDate(DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
    final date = _date;
    if (date != null && _verifiedSelection == null) {
      widget.onSelectionChanged(
        TravelDateSelection(schedule: _manualSchedule(date)),
      );
    }
  }

  /// Back to the idle Today / Tomorrow / pick-a-date state.
  void _reset() {
    setState(() {
      _datelessChosen = false;
      _date = null;
      _time = null;
      _verifiedSummary = null;
      _verifiedSelection = null;
      _checked = false;
      _checkFailed = false;
    });
    widget.onSelectionChanged(null);
  }

  /// Checks the provider for departures on exactly [date]; a match attaches
  /// the real schedule silently, a miss stays honest date-only.
  Future<void> _verifyDate(DateTime date) async {
    // Guarded for widget tests without DI.
    if (!GetIt.I.isRegistered<SearchUpcomingFlightsByNumberUseCase>()) return;
    setState(() => _verifying = true);
    widget.onBusyChanged(true);
    List<FlightSummary> found = const [];
    var failed = false;
    try {
      found = await GetIt.I.get<SearchUpcomingFlightsByNumberUseCase>().call(
        widget.flightNumber,
        date: date,
      );
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
    if (!mounted || _date != date) return;
    final matches = [
      for (final summary in _matchesForVerify(found))
        if (summary.schedule?.departure != null) summary,
    ];
    final match = matches.isEmpty ? null : matches.first;
    final confirmed = widget.confirmedFlight;
    setState(() {
      _verifying = false;
      _checked = !failed;
      _checkFailed = failed;
      // Identity is decided ONCE — at the card the user confirmed. The
      // verified entry only contributes schedule fields (it can be
      // departure-only sparse, e.g. BA117). copyWith keeps the confirmed
      // fr24Id when the dated leg has none.
      _verifiedSummary = match == null
          ? null
          : confirmed?.copyWith(
                  travelDateLocal: match.travelDateLocal,
                  scheduledDeparture: match.scheduledDeparture,
                  scheduledArrival: match.scheduledArrival,
                  fr24Id: match.fr24Id,
                ) ??
                match;
      _verifiedSelection = match == null
          ? null
          : TravelDateSelection(
              schedule: match.schedule!,
              fr24Id: match.fr24Id,
            );
    });
    widget.onBusyChanged(false);
    widget.onSelectionChanged(
      _verifiedSelection ??
          TravelDateSelection(schedule: _manualSchedule(date)),
    );
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

  /// STRICT pair match: the entry must depart from the confirmed origin,
  /// and its arrival must match too whenever the entry knows it (schedule
  /// rows can be departure-only, e.g. BA117). No keep-everything fallback.
  List<FlightSummary> _matchesForVerify(List<FlightSummary> summaries) {
    final departureCodes = _airportCodes(widget.departure);
    final arrivalCodes = _airportCodes(widget.arrival);
    if (departureCodes.isEmpty) return summaries;
    return summaries.where((summary) {
      final origCodes = {
        if (summary.origIcao != null) summary.origIcao!.toUpperCase(),
        if (summary.departure != null) ..._airportCodes(summary.departure!),
      };
      if (origCodes.intersection(departureCodes).isEmpty) return false;
      final destCodes = {
        if (summary.destIcao != null) summary.destIcao!.toUpperCase(),
        if (summary.arrival != null) ..._airportCodes(summary.arrival!),
      };
      if (destCodes.isEmpty) return true; // departure-only schedule row
      return arrivalCodes.isEmpty ||
          destCodes.intersection(arrivalCodes).isNotEmpty;
    }).toList();
  }

  Set<String> _airportCodes(Airport airport) {
    return {
      if (airport.iataCode.trim().isNotEmpty)
        airport.iataCode.trim().toUpperCase(),
      if (airport.icaoCode.trim().isNotEmpty)
        airport.icaoCode.trim().toUpperCase(),
    };
  }

  /// Manual date (+ optional time): the time is wall-clock at the departure
  /// airport, converted through the airport's timezone — same shape as a
  /// provider schedule.
  FlightSchedule _manualSchedule(DateTime date) {
    final time = _time;
    final service = _timezoneService;
    if (time == null || service == null) {
      return FlightSchedule.dateOnly(date);
    }
    final utc = service.localTimeToUtc(
      widget.departure,
      date,
      hour: time.hour,
      minute: time.minute,
    );
    if (utc == null) return FlightSchedule.dateOnly(date);
    return FlightSchedule(
      travelDate: DateTime(date.year, date.month, date.day),
      departure: ZonedInstant(
        utc: utc,
        offsetMinutes: service.utcOffsetMinutes(widget.departure, utc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateT = context.t.createFlight.travelDate;
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _datelessChosen
            ? _datelessWidgets(dateT, theme)
            : _date == null
            ? _idleWidgets(dateT, theme)
            : _pickedWidgets(dateT, theme),
      ),
    );
  }

  Widget? _identityStrip() {
    final confirmed = widget.confirmedFlight;
    if (confirmed == null) return null;
    return CompactFlightStrip(
      summary: confirmed,
      isSelected: true,
      showRoute: widget.stripShowRoute,
      onTap: widget.onStripTap,
      trailing: widget.stripTrailing,
    );
  }

  List<Widget> _idleWidgets(dynamic dateT, ThemeData theme) {
    final today = _today();
    final strip = widget.showIdleStrip ? _identityStrip() : null;
    return [
      if (strip != null) ...[strip, const SizedBox(height: 16)],
      Text(
        dateT.stepTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _DateChip(
              label: dateT.today,
              onTap: () => _selectDate(today),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DateChip(
              label: dateT.tomorrow,
              onTap: () => _selectDate(today.add(const Duration(days: 1))),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: _DateChip(
          label: dateT.customDate,
          icon: Icons.calendar_month_rounded,
          onTap: _pickCustomDate,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: _DateChip(
          label: dateT.noDateYet,
          icon: Icons.event_busy_rounded,
          onTap: _selectDateless,
        ),
      ),
    ];
  }

  /// The explicit dateless choice, confirmed visibly like a date pick.
  List<Widget> _datelessWidgets(dynamic dateT, ThemeData theme) {
    final strip = _identityStrip();
    return [
      if (strip != null) ...[strip, const SizedBox(height: 12)],
      SizedBox(
        width: double.infinity,
        child: _DateChip(
          label: dateT.noDateYet,
          icon: Icons.event_busy_rounded,
          isSelected: true,
          onTap: _reset,
        ),
      ),
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerLeft,
        child: TertiaryButton(
          label: dateT.changeDate,
          onPressed: _reset,
          expand: false,
        ),
      ),
    ];
  }

  List<Widget> _pickedWidgets(dynamic dateT, ThemeData theme) {
    final verified = _verifiedSummary;
    final changeDate = Align(
      alignment: Alignment.centerLeft,
      child: TertiaryButton(
        label: dateT.changeDate,
        onPressed: _reset,
        expand: false,
      ),
    );
    if (_verifying) {
      // The strip hides too — nothing but the check until the API answers.
      return [
        const SizedBox(height: 32),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Center(
          child: Text(
            dateT.checkingSchedule,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 32),
      ];
    }
    if (verified != null) {
      // The reveal: the compact strip is REPLACED by the full flight card
      // (identity from the confirmed card, schedule from the verification),
      // with the change-date action kept below it.
      return [
        FlightSummaryCard(summary: verified),
        const SizedBox(height: 6),
        changeDate,
      ];
    }
    final strip = _identityStrip();
    return [
      // Miss: the compact identity stays, with the honest message below.
      if (strip != null) ...[strip, const SizedBox(height: 12)],
      SizedBox(
        width: double.infinity,
        child: _DateChip(
          label: TravelDateFormatUtils.formatShortDate(
            _date!,
            context.dateDisplayFormat,
          ),
          icon: Icons.calendar_month_rounded,
          isSelected: true,
          onTap: _pickCustomDate,
        ),
      ),
      if (_checked || _checkFailed) ...[
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
                _checkFailed
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
      if (_departureTzKnown) ...[
        const SizedBox(height: 4),
        // A hatch, not a headline.
        Align(
          alignment: Alignment.centerLeft,
          child: TertiaryButton(
            label: _time == null
                ? dateT.addDepartureTime
                : dateT.departureTimeAt(time: _formatTime(_time!)),
            onPressed: _pickCustomTime,
            expand: false,
          ),
        ),
      ],
      const SizedBox(height: 6),
      changeDate,
    ];
  }

  String _formatTime(TimeOfDay time) {
    return TravelDateFormatUtils.formatTime(
      DateTime(2000, 1, 1, time.hour, time.minute),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.25),
            width: 1.5,
          ),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
