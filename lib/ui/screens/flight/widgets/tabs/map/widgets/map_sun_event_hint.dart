import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/day_night/route_sun_event_forecast.dart';

class MapSunEventHint extends StatelessWidget {
  const MapSunEventHint({
    required this.forecast,
    this.embedded = false,
    super.key,
  });

  final RouteSunEventForecast forecast;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final minutes = (forecast.eta.inSeconds / 60)
        .ceil()
        .clamp(1, 24 * 60)
        .toInt();
    final label = switch (forecast.type) {
      RouteSunEventType.sunrise => context.t.flight.map.sunriseInMinutes(
        minutes: minutes,
      ),
      RouteSunEventType.sunset => context.t.flight.map.sunsetInMinutes(
        minutes: minutes,
      ),
    };
    final icon = switch (forecast.type) {
      RouteSunEventType.sunrise => Icons.wb_sunny_outlined,
      RouteSunEventType.sunset => Icons.nights_stay_rounded,
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: embedded ? 13 : 14, color: colorScheme.primary),
        const SizedBox(width: DsSpacing.xxs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (embedded
                        ? Theme.of(context).textTheme.labelSmall
                        : Theme.of(context).textTheme.labelMedium)
                    ?.copyWith(
                      color: colorScheme.onSurface.withValues(
                        alpha: embedded ? 0.82 : 1,
                      ),
                      fontWeight: embedded ? FontWeight.w600 : FontWeight.w700,
                    ),
          ),
        ),
      ],
    );

    if (embedded) return content;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(DsRadii.pill),
      ),
      child: content,
    );
  }
}
