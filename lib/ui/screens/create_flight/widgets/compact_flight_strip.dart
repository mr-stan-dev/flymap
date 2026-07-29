import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';

/// One-glance flight identity in two small lines — the "we found your
/// flight" strip. Keeps the date question above the fold; the full
/// [FlightSummaryCard] is the reveal AFTER a date is confirmed.
class CompactFlightStrip extends StatelessWidget {
  const CompactFlightStrip({
    required this.summary,
    this.isSelected = false,
    this.showRoute = true,
    this.onTap,
    this.trailing,
    super.key,
  });

  final FlightSummary summary;
  final bool isSelected;

  /// Prioritize what the user does NOT know yet. Searching by NUMBER they
  /// know the number — lead with the route (codes, cities, countries).
  /// Searching by AIRPORTS (off) they know the route — lead with airline +
  /// number. Same skeleton either way; never duration/distance here.
  final bool showRoute;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final routeLine = [
      summary.departure?.displayCode ?? summary.origIcao ?? '',
      summary.arrival?.displayCode ?? summary.destIcao ?? '',
    ].where((code) => code.isNotEmpty).join(' → ');
    final airlineLine = [
      summary.airlineName,
      summary.flightNumber,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    final citiesLine = [
      _cityLabel(summary.departure),
      _cityLabel(summary.arrival),
    ].where((part) => part.isNotEmpty).join(' → ');
    final aircraft = summary.aircraftType ?? '';

    final title = showRoute ? routeLine : airlineLine;
    final subtitle = showRoute ? citiesLine : aircraft;
    final detail = showRoute
        ? [airlineLine, aircraft].where((part) => part.isNotEmpty).join(' · ')
        : '';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.25),
            width: 1.5,
          ),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? airlineLine : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }

  String _cityLabel(Airport? airport) {
    if (airport == null) return '';
    final city = airport.city.trim();
    final country = airport.countryCode.trim().toUpperCase();
    if (city.isEmpty) return country;
    return country.isEmpty ? city : '$city, $country';
  }
}
