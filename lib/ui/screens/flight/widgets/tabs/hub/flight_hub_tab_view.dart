import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_forecast_body.dart';
import 'package:flymap/ui/screens/flight/sections/flight_articles_screen.dart';
import 'package:flymap/ui/screens/flight/sections/flight_places_screen.dart';
import 'package:flymap/ui/screens/flight/sections/flight_timeline_screen.dart';
import 'package:flymap/ui/screens/flight/sections/flight_weather_screen.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_weather_cubit.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/route_progress_card.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/shared/tab_state_placeholder.dart';
import 'package:flymap/ui/screens/settings/distance_unit_context.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_grouping.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/utils/duration_format_utils.dart';
import 'package:flymap/ui/screens/settings/date_display_format_context.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';

/// The Flight hub: header with the flight's identity and key facts, then
/// one row per section — Timeline, Places, Weather, Articles — each
/// pushing its own screen. The rows carry live previews (counts, the
/// weather verdict) so the hub reads as a summary, not a menu.
class FlightHubTabView extends StatefulWidget {
  const FlightHubTabView({required this.topPadding, super.key});

  final double topPadding;

  @override
  State<FlightHubTabView> createState() => _FlightHubTabViewState();
}

class _FlightHubTabViewState extends State<FlightHubTabView> {
  @override
  void initState() {
    super.initState();
    // The weather row preview needs the forecast; same access gating as
    // everywhere else lives inside the cubit call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final weatherCubit = context.read<FlightWeatherCubit>();
      final hasProAccess =
          weatherCubit.flight.hasProAccess ||
          context.read<SubscriptionCubit>().state.isPro;
      unawaited(weatherCubit.fetchIfNeeded(hasProAccess: hasProAccess));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightScreenCubit, FlightScreenState>(
      builder: (context, state) {
        final loaded = switch (state) {
          FlightScreenLoaded() => state,
          FlightScreenError(:final flight?) => FlightScreenLoaded(
            flight: flight,
            routeRegions: flight.info.routeRegions,
          ),
          _ => null,
        };
        if (loaded == null) {
          return FlightTabStatePlaceholder(
            icon: Icons.flight_takeoff_rounded,
            text: context.t.flight.info.loadingRouteInformation,
          );
        }
        return _HubBody(state: loaded, topPadding: widget.topPadding);
      },
    );
  }
}

class _HubBody extends StatelessWidget {
  const _HubBody({required this.state, required this.topPadding});

  final FlightScreenLoaded state;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final t = context.t.flight.hub;
    final flight = state.flight;
    final route = flight.route;
    final regions = state.routeRegions;
    final places = flight.info.poi;
    final articles = flight.info.articles;

    final isUpcoming = flight.status == FlightStatus.upcoming;
    final hasGpsFix =
        state.gps.data?.latitude != null && state.gps.data?.longitude != null;
    final isGpsStale =
        state.gps.status == GpsStatus.searching && state.gps.lastFixAt != null;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(12, topPadding, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FlightBoardingCard(
              flight: flight,
              totalMinutes: _totalMinutes(flight),
            ),
            const SizedBox(height: DsSpacing.sm),
            if (!isUpcoming && hasGpsFix) ...[
              RouteProgressCard(
                route: route,
                coveredDistanceKm: state.routeCoveredDistanceKm,
                isStale: isGpsStale,
              ),
              const SizedBox(height: DsSpacing.sm),
            ],
            _HubSectionRow(
              icon: Icons.timeline_rounded,
              title: t.timelineTitle,
              subtitle: regions.isEmpty
                  ? context.t.flight.route.noSavedOfflineRegions
                  : t.timelineSubtitle(count: '${regions.length}'),
              enabled: true,
              onTap: () => _push(context, const FlightTimelineScreen()),
            ),
            _HubSectionRow(
              icon: Icons.place_rounded,
              title: t.placesTitle,
              subtitle: places.isEmpty
                  ? t.noPlaces
                  : t.placesSubtitle(count: '${places.length}'),
              enabled: places.isNotEmpty,
              onTap: () => _push(context, const FlightPlacesScreen()),
            ),
            _WeatherSectionRow(
              flight: flight,
              onTap: () => _push(context, FlightWeatherScreen(flight: flight)),
            ),
            _HubSectionRow(
              icon: Icons.article_rounded,
              title: t.articlesTitle,
              subtitle: articles.isEmpty
                  ? context.t.flight.info.noOfflineArticles
                  : t.articlesSubtitle(count: '${articles.length}'),
              enabled: articles.isNotEmpty,
              onTap: () => _push(context, const FlightArticlesScreen()),
            ),
          ],
        ),
      ),
    );
  }

  int _totalMinutes(Flight flight) {
    final route = flight.route;
    final info = flight.info;
    final routeCruiseSpeedKmh =
        route.metrics.cruiseSpeedKmh?.round() ?? info.routeCruiseSpeedKmh;
    final displayBlockMinutes = route.durations.displayBlockMinutes;
    final routeBlockMinutes = displayBlockMinutes > 0
        ? displayBlockMinutes
        : info.routeCruiseMinutes;
    final groups = RouteTimelineGrouping.groupByTimeline(
      state.routeRegions,
      cruiseSpeedKmh: routeCruiseSpeedKmh,
      maxTimelineMinutes: route.isHistoricalTrack ? routeBlockMinutes : null,
      routeDistanceKm: route.distanceInKm,
      blockMinutes: routeBlockMinutes,
      useTotalDurationProportion: !route.isHistoricalTrack,
    );
    return RouteTimelineGrouping.arrivalMinutes(
      routeDistanceKm: route.distanceInKm,
      blockMinutes: routeBlockMinutes,
      cruiseSpeedKmh: routeCruiseSpeedKmh,
      groups: groups,
      blockMinutesIsAuthoritative: route.isHistoricalTrack,
    );
  }

  void _push(BuildContext context, Widget screen) {
    final flightCubit = context.read<FlightScreenCubit>();
    final weatherCubit = context.read<FlightWeatherCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: flightCubit),
            BlocProvider.value(value: weatherCubit),
          ],
          child: screen,
        ),
      ),
    );
  }
}

/// The one flight card: boarding-pass layout with each fact exactly once.
/// Codes + airport names (cities/countries live in the overlay app bar),
/// schedule + flight number + airline, duration + distance chips.
class _FlightBoardingCard extends StatelessWidget {
  const _FlightBoardingCard({required this.flight, required this.totalMinutes});

  final Flight flight;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final route = flight.route;
    final schedule = flight.schedule;
    final operational = flight.operationalData;
    final flightNumber = operational?.flightNumber.trim() ?? '';
    final airline = operational?.airlineName?.trim() ?? '';

    final scheduleParts = <String>[
      if (schedule != null)
        TravelDateFormatUtils.formatShortDate(
          schedule.travelDate,
          context.dateDisplayFormat,
        ),
      if (schedule?.departureLocal != null)
        TravelDateFormatUtils.formatTime(schedule!.departureLocal!),
      if (flightNumber.isNotEmpty) flightNumber,
    ];

    final distanceLabel = UnitFormatUtils.formatDistanceApprox(
      route.displayDistanceKm.toDouble(),
      context.distanceUnit,
    );
    final durationLabel = DurationFormatUtils.formatApprox(
      context,
      totalMinutes,
    );

    TextStyle? codeStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );
    TextStyle? nameStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.departure.displayCode, style: codeStyle),
                    const SizedBox(height: 2),
                    Text(
                      route.departure.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  width: 72,
                  child: Row(
                    children: [
                      const Expanded(child: _DashedLine()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Transform.rotate(
                          angle: math.pi / 2,
                          child: Icon(
                            Icons.flight,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const Expanded(child: _DashedLine()),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(route.arrival.displayCode, style: codeStyle),
                    const SizedBox(height: 2),
                    Text(
                      route.arrival.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: nameStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (scheduleParts.isNotEmpty || airline.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (scheduleParts.isNotEmpty)
              Text(
                scheduleParts.join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (airline.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                airline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (durationLabel != null)
                _FactChip(icon: Icons.schedule, label: durationLabel),
              _FactChip(icon: Icons.route, label: distanceLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 2),
      painter: _DashedLinePainter(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

/// Weather row: the preview IS the verdict when the forecast is in.
class _WeatherSectionRow extends StatelessWidget {
  const _WeatherSectionRow({required this.flight, required this.onTap});

  final Flight flight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t.flight.hub;
    final weatherStrings = context.t.createFlight.weather;
    final hasProAccess =
        flight.hasProAccess ||
        context.select((SubscriptionCubit cubit) => cubit.state.isPro);

    return BlocBuilder<FlightWeatherCubit, FlightWeatherState>(
      builder: (context, state) {
        final weather = state.weather;
        final String subtitle;
        IconData icon = Icons.cloud_rounded;
        if (!hasProAccess) {
          subtitle = t.weatherLocked;
          icon = Icons.lock_rounded;
        } else if (FlightWeatherVerdictPolicy.isBeyondForecastHorizon(
          flight.schedule,
          now: DateTime.now(),
        )) {
          subtitle = t.weatherTooEarly;
          icon = Icons.notifications_active_rounded;
        } else if (state.isLoading) {
          subtitle = weatherStrings.loading;
        } else if (weather != null && weather.samples.isNotEmpty) {
          final verdict = FlightWeatherVerdictPolicy.overallVerdict(
            weather.samples,
          );
          final (emoji, title, _) = verdictPresentation(
            verdict,
            weatherStrings,
          );
          subtitle =
              '$emoji $title · '
              '${weatherStrings.updatedAt(time: TravelDateFormatUtils.formatTime(weather.fetchedAt))}';
        } else {
          subtitle = t.weatherCheck;
        }

        return _HubSectionRow(
          icon: icon,
          title: t.weatherTitle,
          subtitle: subtitle,
          enabled: true,
          onTap: onTap,
        );
      },
    );
  }
}

class _HubSectionRow extends StatelessWidget {
  const _HubSectionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(
                      alpha: enabled ? 0.10 : 0.05,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: enabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
