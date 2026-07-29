import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';

class TravelDatePickArgs {
  const TravelDatePickArgs({
    required this.departure,
    required this.arrival,
    this.hasPendingFlightUnlock = false,
  });

  final Airport departure;
  final Airport arrival;
  final bool hasPendingFlightUnlock;
}

/// Dedicated "When are you flying?" step for APPROXIMATE flights only —
/// a plain Today..+6 calendar grid plus a custom date; there is no
/// schedule to verify. Real flights pick their date inline on the search
/// screens via TravelDateSection. The dateless escape hatch stays — a date
/// is never required.
class TravelDatePickScreen extends StatefulWidget {
  const TravelDatePickScreen({required this.args, super.key});

  final TravelDatePickArgs args;

  @override
  State<TravelDatePickScreen> createState() => _TravelDatePickScreenState();
}

class _TravelDatePickScreenState extends State<TravelDatePickScreen> {
  static const int _windowDays = 7;

  late final List<DateTime> _options;
  int? _selectedIndex;
  DateTime? _customDate;
  bool _customSelected = false;

  @override
  void initState() {
    super.initState();
    final today = _today();
    _options = List.generate(
      _windowDays,
      (index) => today.add(Duration(days: index)),
    );
    // No preselection on purpose: the date must be an explicit choice —
    // Continue stays disabled until one is made, and the dateless escape
    // hatch covers everyone else.
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _optionLabel(DateTime date) {
    final daysAway = date.difference(_today()).inDays;
    final dateT = context.t.createFlight.travelDate;
    return switch (daysAway) {
      0 => dateT.today,
      1 => dateT.tomorrow,
      _ => TravelDateFormatUtils.formatShortDate(date),
    };
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
    if (!withoutDate) {
      if (_customSelected && _customDate != null) {
        schedule = FlightSchedule.dateOnly(_customDate!);
      } else if (_selectedIndex != null) {
        schedule = FlightSchedule.dateOnly(_options[_selectedIndex!]);
      }
    }
    AppRouter.goToFlightOverview(
      context,
      departure: widget.args.departure,
      arrival: widget.args.arrival,
      flightNumber: null,
      fr24Id: null,
      schedule: schedule,
      hasPendingFlightUnlock: widget.args.hasPendingFlightUnlock,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateT = context.t.createFlight.travelDate;
    final theme = Theme.of(context);
    final routeLabel =
        '${widget.args.departure.displayCode} → '
        '${widget.args.arrival.displayCode}';
    final canContinue = _selectedIndex != null || _customSelected;

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
                child: ListView(
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
                    _DateOptionRow(
                      icon: Icons.calendar_month_rounded,
                      label: _customDate == null
                          ? dateT.customDate
                          : TravelDateFormatUtils.formatShortDate(_customDate!),
                      isSelected: _customSelected,
                      onTap: _pickCustomDate,
                    ),
                  ],
                ),
              ),
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
