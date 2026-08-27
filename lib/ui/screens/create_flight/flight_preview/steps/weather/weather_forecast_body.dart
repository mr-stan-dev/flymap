import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flymap/data/notifications/flight_notification_scheduler.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/settings/date_display_format_context.dart';
import 'package:flymap/ui/screens/settings/temperature_unit_context.dart';
import 'package:flymap/utils/unit_format_utils.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_route_map_card.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_symbols.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_wind_presentation.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// The complete weather forecast experience, shared by the create-flight
/// weather step and the flight screen's weather section: Pro forecast
/// (airport cards, animated cloud map, verdict), the free blurred teaser,
/// the beyond-horizon explainer with its notification-permission switch,
/// plus loading and failed states. Hosts own the surrounding chrome
/// (Continue buttons, app bars) and the data lifecycle.
class WeatherForecastBody extends StatelessWidget {
  const WeatherForecastBody({
    required this.route,
    required this.schedule,
    required this.weather,
    required this.isLoading,
    required this.isProUser,
    required this.onRetry,
    required this.onPremiumGateTap,
    this.onPickDate,
    this.onGoBack,
    this.onRefresh,
    this.failedCopy,
    this.flightId,
    super.key,
  });

  final FlightRoute? route;
  final FlightSchedule? schedule;
  final FlightWeather? weather;
  final bool isLoading;
  final bool isProUser;
  final VoidCallback onRetry;
  final VoidCallback onPremiumGateTap;

  /// Saved flight id, when this body shows a stored flight (the weather
  /// screen). Threaded to the map card so its satellite base comes from the
  /// per-flight offline cache. Null in the creation flow (no saved flight).
  final String? flightId;

  /// Handles picking a complete flight date and time when there is none.
  /// When null, the prompt explains that a real flight must be re-selected.
  final VoidCallback? onPickDate;

  /// Shortcut from the no-date state back to flight selection (where a real
  /// flight's date is chosen). Shown only when [onPickDate] is null.
  final VoidCallback? onGoBack;

  /// Pull-to-refresh on the loaded forecast: forces a fresh fetch (the 6h
  /// cache only governs the automatic refresh on open). Enabled only when the
  /// host provides it.
  final Future<void> Function()? onRefresh;

  /// Overrides the generic failed-load copy — the flight screen uses it to
  /// explain that no forecast was downloaded before takeoff.
  final String? failedCopy;

  /// Beyond the reliable horizon nothing was (or should be) fetched — the
  /// body explains instead of pretending to fail. Exposed so hosts can
  /// adjust their chrome (e.g. the step's Continue label).
  static bool isBeyondHorizon({
    required bool isProUser,
    required FlightWeather? weather,
    required FlightSchedule? schedule,
  }) {
    return isProUser &&
        weather == null &&
        FlightWeatherVerdictPolicy.isBeyondForecastHorizon(
          schedule,
          now: DateTime.now(),
        );
  }

  static bool isPast({
    required bool isProUser,
    required FlightWeather? weather,
    required FlightSchedule? schedule,
  }) {
    return isProUser &&
        weather == null &&
        FlightWeatherVerdictPolicy.isInPast(schedule, now: DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final weather = this.weather;

    if (!isProUser) {
      // Free flights never fetch the forecast: a labeled demo behind
      // glass + upgrade pitch (the host renders the upgrade actions).
      return _WeatherTeaser(route: route, onPremiumGateTap: onPremiumGateTap);
    }
    if ((schedule == null ||
            schedule?.timePrecision == FlightScheduleTimePrecision.dateOnly) &&
        weather == null) {
      // A date without a departure time is no more meaningful than no date:
      // both states require one complete manual date-and-time choice.
      return _NoDatePrompt(onPickDate: onPickDate, onGoBack: onGoBack);
    }
    if (isPast(isProUser: isProUser, weather: weather, schedule: schedule)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 14),
              Text(
                t.pastForecastTitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                t.pastForecastBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (isBeyondHorizon(
      isProUser: isProUser,
      weather: weather,
      schedule: schedule,
    )) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                t.forecastTooFarTitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                t.forecastTooFarBody(
                  days:
                      '${FlightWeatherVerdictPolicy.reliableForecastDaysAhead}',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              const _ForecastNotificationToggle(),
            ],
          ),
        ),
      );
    }
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(t.loading, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    if (weather == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                failedCopy ?? t.loadFailed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SecondaryButton(
                label: context.t.common.retry,
                onPressed: onRetry,
                expand: false,
              ),
            ],
          ),
        ),
      );
    }
    return _WeatherContent(
      route: route,
      weather: weather,
      isProUser: isProUser,
      onPremiumGateTap: onPremiumGateTap,
      onRefresh: onRefresh,
      flightId: flightId,
    );
  }
}

/// The promised forecast alert can only arrive if notifications are
/// allowed. Shown ONLY while the permission is missing: a hint + switch
/// that requests it (falling through to app settings when permanently
/// denied); once granted the row disappears. Re-checks on app resume so a
/// grant made in system settings is picked up.
class _ForecastNotificationToggle extends StatefulWidget {
  const _ForecastNotificationToggle();

  @override
  State<_ForecastNotificationToggle> createState() =>
      _ForecastNotificationToggleState();
}

class _ForecastNotificationToggleState
    extends State<_ForecastNotificationToggle>
    with WidgetsBindingObserver {
  /// Null while the first check runs — the row stays hidden rather than
  /// flashing in and out.
  bool? _granted;
  bool _requesting = false;

  NotificationPermissionService? get _service =>
      GetIt.I.isRegistered<NotificationPermissionService>()
      ? GetIt.I.get<NotificationPermissionService>()
      : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final service = _service;
    if (service == null) return;
    final granted = await service.isGranted();
    if (mounted) setState(() => _granted = granted);
  }

  Future<void> _request() async {
    final service = _service;
    if (service == null || _requesting) return;
    setState(() => _requesting = true);
    final granted = await service.request();
    if (granted && GetIt.I.isRegistered<FlightNotificationScheduler>()) {
      // Alerts for already-saved flights can now actually be placed.
      unawaited(GetIt.I.get<FlightNotificationScheduler>().resyncAll());
    }
    if (mounted) {
      setState(() {
        _granted = granted;
        _requesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_granted != false) return const SizedBox.shrink();
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.notificationPermissionHint,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 4),
          Switch.adaptive(
            value: false,
            onChanged: _requesting ? null : (_) => unawaited(_request()),
          ),
        ],
      ),
    );
  }
}

/// Free-flight weather: the whole real-looking screen — mocked airport
/// cards AND the animated demo cloud map on the user's route — sits behind
/// one frosted blur, so the drifting clouds and the flying plane shimmer
/// through without any fake number being readable. Centered on the glass:
/// the lock and the pitch; the host renders the upgrade actions. No
/// weather API call ever happens for free flights.
/// Shown for a Pro flight with no date. Approximate flights (with a
/// [onPickDate] handler) get an inline date-and-time picker; real flights get
/// an explanation to re-select the flight with a date, plus an optional
/// [onGoBack] shortcut back to flight selection.
class _NoDatePrompt extends StatelessWidget {
  const _NoDatePrompt({this.onPickDate, this.onGoBack});

  final VoidCallback? onPickDate;
  final VoidCallback? onGoBack;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              t.noDateTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              onPickDate != null ? t.noDatePickBody : t.noDateRealBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onPickDate != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                label: t.noDatePickButton,
                onPressed: onPickDate!,
                expand: false,
              ),
            ] else if (onGoBack != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onGoBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(t.noDateBackButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeatherTeaser extends StatelessWidget {
  const _WeatherTeaser({required this.route, required this.onPremiumGateTap});

  final FlightRoute? route;
  final VoidCallback onPremiumGateTap;

  /// Plausible canned forecasts for the blurred cards. Fixed instants —
  /// unreadable behind the blur, deterministic in tests.
  static final AirportWeather _demoDeparture = AirportWeather(
    timeUtc: DateTime.utc(2026, 5, 15, 8),
    utcOffsetMinutes: 0,
    temperatureC: 21,
    windSpeedMs: 3,
    precipitationMm: 0,
    cloudCoverPercent: 35,
    symbolCode: 'partlycloudy_day',
  );
  static final AirportWeather _demoArrival = AirportWeather(
    timeUtc: DateTime.utc(2026, 5, 15, 11),
    utcOffsetMinutes: 0,
    temperatureC: 24,
    windSpeedMs: 5,
    precipitationMm: 0,
    cloudCoverPercent: 10,
    symbolCode: 'clearsky_day',
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final route = this.route;

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: theme.textTheme.titleLarge),
                  if (route != null) ...[
                    const SizedBox(height: 14),
                    _AirportWeatherCards(
                      route: route,
                      departure: _demoDeparture,
                      arrival: _demoArrival,
                      showTime: false,
                    ),
                    const SizedBox(height: 14),
                    // Square map shrunk to whatever height remains, so the
                    // whole tease always fits one screen.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = math.min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          if (size <= 0) return const SizedBox.shrink();
                          return Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: WeatherRouteMapCard(
                                route: route,
                                samples: const [],
                                isProUser: false,
                                isDemo: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Dim the glass so the pitch reads without any card chrome —
        // classic locked-content look.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0x59000000)),
          ),
        ),
        // Just the lock and the pitch — the actions live in the host's
        // bottom chrome (upgrade primary, continue-without tertiary).
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.proTeaserTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({
    required this.route,
    required this.weather,
    required this.isProUser,
    required this.onPremiumGateTap,
    this.onRefresh,
    this.flightId,
  });

  final FlightRoute? route;
  final FlightWeather weather;
  final bool isProUser;
  final VoidCallback onPremiumGateTap;
  final Future<void> Function()? onRefresh;
  final String? flightId;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final route = this.route;

    final list = ListView(
      // Always scrollable so pull-to-refresh works even when the content fits.
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        Text(t.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        _AirportWeatherCards(
          route: route,
          departure: weather.departure,
          arrival: weather.arrival,
          arrivalIsNextDay: _arrivalIsNextDay,
        ),
        if (route != null && weather.samples.isNotEmpty) ...[
          const SizedBox(height: 14),
          WeatherRouteMapCard(
            // The card owns decoded ui.Images and async rasterization state.
            // A newly fetched immutable forecast must get a fresh State so
            // airport cards, verdict and animation can never describe
            // different forecast generations.
            key: ObjectKey(weather),
            route: route,
            samples: weather.samples,
            areaSamples: weather.areaSamples,
            isProUser: isProUser,
            flightId: flightId,
          ),
          if (!isProUser) ...[
            const SizedBox(height: 10),
            PremiumButton(
              label: context.t.common.upgrade,
              icon: Icons.workspace_premium_rounded,
              onPressed: onPremiumGateTap,
            ),
          ],
          const SizedBox(height: 10),
          _WeatherVerdictChip(weather: weather),
        ],
        const SizedBox(height: 14),
        Text(
          '${TravelDateFormatUtils.formatForecastFreshness(weather.fetchedAt, context.dateDisplayFormat)}'
          ' · ${t.hedge}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(top: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
              textStyle: theme.textTheme.bodySmall,
            ),
            onPressed: () => unawaited(
              launchUrl(
                Uri.parse(weather.attribution.licenseUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
            child: Text(
              t.attribution(
                provider: weather.attribution.providerName,
                license: weather.attribution.licenseName,
              ),
            ),
          ),
        ),
      ],
    );

    final refresh = onRefresh;
    if (refresh == null) return list;
    return RefreshIndicator(onRefresh: refresh, child: list);
  }

  /// True when the arrival's local calendar date is one day after the
  /// departure's — the arrival card marks it "(tomorrow)".
  bool get _arrivalIsNextDay {
    DateTime dateOnly(DateTime value) =>
        DateTime(value.year, value.month, value.day);
    return dateOnly(
          weather.arrival.timeLocal,
        ).difference(dateOnly(weather.departure.timeLocal)).inDays ==
        1;
  }
}

/// Full-width airport summaries keep the route order obvious and give the
/// weather overview enough room to remain one compact horizontal row.
class _AirportWeatherCards extends StatelessWidget {
  const _AirportWeatherCards({
    required this.route,
    required this.departure,
    required this.arrival,
    this.showTime = true,
    this.arrivalIsNextDay = false,
  });

  final FlightRoute? route;
  final AirportWeather departure;
  final AirportWeather arrival;
  final bool showTime;
  final bool arrivalIsNextDay;

  @override
  Widget build(BuildContext context) {
    Widget card({required bool departureCard}) {
      final airport = departureCard ? route?.departure : route?.arrival;
      return _AirportWeatherCard(
        key: ValueKey(
          departureCard
              ? 'departure-airport-weather-card'
              : 'arrival-airport-weather-card',
        ),
        code: airport?.displayCode ?? '',
        city: airport?.city ?? '',
        countryCode: airport?.countryCode ?? '',
        coordinate: airport?.latLon,
        weather: departureCard ? departure : arrival,
        showTime: showTime,
        isNextDay: !departureCard && arrivalIsNextDay,
        isDeparture: departureCard,
      );
    }

    return Column(
      key: const ValueKey('airport-weather-cards-column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card(departureCard: true),
        const SizedBox(height: 10),
        card(departureCard: false),
      ],
    );
  }
}

class _WeatherVerdictChip extends StatelessWidget {
  const _WeatherVerdictChip({required this.weather});

  final FlightWeather weather;

  @override
  Widget build(BuildContext context) {
    final verdict = FlightWeatherVerdictPolicy.overallVerdict(weather.samples);
    final (emoji, title, _) = verdictPresentation(
      verdict,
      context.t.createFlight.weather,
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Align(
      key: const ValueKey('weather-verdict-chip'),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AirportWeatherCard extends StatelessWidget {
  const _AirportWeatherCard({
    required this.code,
    required this.city,
    required this.countryCode,
    required this.coordinate,
    required this.weather,
    required this.isDeparture,
    this.showTime = true,
    this.isNextDay = false,
    super.key,
  });

  final String code;
  final String city;
  final String countryCode;
  final LatLng? coordinate;
  final AirportWeather weather;
  final bool isDeparture;

  /// False only for intentionally obscured demo cards.
  final bool showTime;

  /// Arrival lands on the day after departure — mark it "(tomorrow)".
  final bool isNextDay;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final symbol = weatherSymbolKind(
      weather.symbolCode,
      weather.cloudCoverPercent,
      isDaytime: weatherIsDaytime(
        timeUtc: weather.timeUtc,
        utcOffsetMinutes: weather.utcOffsetMinutes,
        coordinate: coordinate,
      ),
      precipitationMm: weather.precipitationMm,
    );
    final flagCode = countryCode.trim().toUpperCase();
    final formattedTime = TravelDateFormatUtils.formatTime(weather.timeLocal);
    final utcOffsetLabel = TravelDateFormatUtils.formatUtcOffset(
      weather.utcOffsetMinutes,
    );

    var dateLine = TravelDateFormatUtils.formatShortDate(
      weather.timeLocal,
      context.dateDisplayFormat,
    );
    if (isNextDay) dateLine = '$dateLine (${t.tomorrow})';
    final timeAndDate = [
      if (showTime)
        '$formattedTime${utcOffsetLabel == null ? '' : ' $utcOffsetLabel'}',
      dateLine,
    ].join(' · ');

    final header = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    code,
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    if (flagCode.length == 2) ...[
                      ClipOval(
                        child: CountryFlag.fromCountryCode(
                          flagCode,
                          width: 12,
                          height: 12,
                          shape: const Rectangle(),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        flagCode.length == 2 ? '$city · $flagCode' : city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                timeAndDate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _AirportWeatherSummary(weather: weather, symbol: symbol),
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
    if (weather.timeline.length < 2) {
      return Material(
        color: colorScheme.surfaceContainerHigh,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: header,
        ),
      );
    }

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey('airport-weather-expansion-$code'),
        shape: shape,
        collapsedShape: shape,
        backgroundColor: colorScheme.surfaceContainerHigh,
        collapsedBackgroundColor: colorScheme.surfaceContainerHigh,
        tilePadding: const EdgeInsets.only(left: 12, right: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        dense: true,
        title: header,
        children: [
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 10),
          _AirportForecastTimeline(
            weather: weather,
            coordinate: coordinate,
            isDeparture: isDeparture,
          ),
        ],
      ),
    );
  }
}

class _AirportWeatherSummary extends StatelessWidget {
  const _AirportWeatherSummary({required this.weather, required this.symbol});

  final AirportWeather weather;
  final WeatherSymbolKind symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final temperature = weather.temperatureC;
    final precipitation = weather.precipitationMm ?? 0;

    return SizedBox(
      width: 118,
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 48,
            height: 44,
            child: SvgPicture.asset(
              symbol.assetPath,
              key: ValueKey('airport-weather-icon-${symbol.name}'),
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    temperature == null
                        ? '–'
                        : UnitFormatUtils.formatTemperatureValue(
                            temperature,
                            context.temperatureUnit,
                          ),
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (weather.windSpeedMs != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _WindIndicator(speedMs: weather.windSpeedMs!),
                  ),
                if (precipitation > 0)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${precipitation.toStringAsFixed(1)} mm/h',
                      maxLines: 1,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AirportForecastTimeline extends StatelessWidget {
  const _AirportForecastTimeline({
    required this.weather,
    required this.coordinate,
    required this.isDeparture,
  });

  final AirportWeather weather;
  final LatLng? coordinate;
  final bool isDeparture;

  @override
  Widget build(BuildContext context) {
    final slices = weather.timeline;
    if (slices.length < 2) return const SizedBox.shrink();
    final firstTime = slices.first.timeUtc;
    final lastTime = slices.last.timeUtc;
    final totalSeconds = lastTime.difference(firstTime).inSeconds;
    final eventProgress = totalSeconds <= 0
        ? 0.5
        : weather.timeUtc.difference(firstTime).inSeconds / totalSeconds;

    const timelineHeight = 132.0;
    const trackCenterY = 28.0;
    const intervalDotSize = 6.0;
    const markerSize = 22.0;

    return SizedBox(
      height: timelineHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = math.max(
            constraints.maxWidth,
            slices.length * 66.0,
          );
          final cellWidth = contentWidth / slices.length;
          final trackLeft = cellWidth / 2;
          final trackWidth = contentWidth - cellWidth;
          final markerLeft =
              (trackLeft +
                      eventProgress.clamp(0.0, 1.0) * trackWidth -
                      markerSize / 2)
                  .clamp(0.0, contentWidth - markerSize);
          final t = context.t.createFlight.weather;
          final eventLabel = isDeparture ? t.departureLabel : t.arrivalLabel;
          final eventTime = TravelDateFormatUtils.formatTime(weather.timeLocal);
          final primary = Theme.of(context).colorScheme.primary;
          final markerKind = isDeparture ? 'departure' : 'arrival';

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              height: timelineHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: trackLeft,
                    right: trackLeft,
                    top: trackCenterY - 0.5,
                    child: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  Row(
                    children: [
                      for (final slice in slices)
                        _AirportForecastPoint(
                          slice: slice,
                          utcOffsetMinutes: weather.utcOffsetMinutes,
                          coordinate: coordinate,
                          width: cellWidth,
                          topSpacing: trackCenterY - intervalDotSize / 2,
                        ),
                    ],
                  ),
                  Positioned(
                    left: markerLeft + markerSize / 2 - 0.75,
                    top: markerSize,
                    child: Container(
                      key: ValueKey(
                        'airport-weather-event-connector-$markerKind',
                      ),
                      width: 1.5,
                      height: trackCenterY - markerSize,
                      color: primary,
                    ),
                  ),
                  Positioned(
                    left: markerLeft + (markerSize - intervalDotSize) / 2,
                    top: trackCenterY - intervalDotSize / 2,
                    child: Container(
                      key: ValueKey('airport-weather-event-dot-$markerKind'),
                      width: intervalDotSize,
                      height: intervalDotSize,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: markerLeft,
                    top: 0,
                    child: Semantics(
                      label: '$eventLabel $eventTime',
                      child: Tooltip(
                        message: '$eventLabel · $eventTime',
                        child: Container(
                          key: ValueKey(
                            'airport-weather-event-marker-$markerKind',
                          ),
                          width: markerSize,
                          height: markerSize,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDeparture
                                ? Icons.flight_takeoff_rounded
                                : Icons.flight_land_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AirportForecastPoint extends StatelessWidget {
  const _AirportForecastPoint({
    required this.slice,
    required this.utcOffsetMinutes,
    required this.coordinate,
    required this.width,
    required this.topSpacing,
  });

  final AirportForecastSlice slice;
  final int utcOffsetMinutes;
  final LatLng? coordinate;
  final double width;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final localTime = slice.timeUtc.add(Duration(minutes: utcOffsetMinutes));
    final symbol = weatherSymbolKind(
      slice.symbolCode,
      slice.cloudCoverPercent,
      isDaytime: weatherIsDaytime(
        timeUtc: slice.timeUtc,
        utcOffsetMinutes: utcOffsetMinutes,
        coordinate: coordinate,
      ),
      precipitationMm: slice.precipitationMm,
    );
    final temperature = slice.temperatureC;
    final precipitation = slice.precipitationMm ?? 0;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(height: topSpacing),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            TravelDateFormatUtils.formatTime(localTime),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(
            width: 38,
            height: 30,
            child: SvgPicture.asset(
              symbol.assetPath,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          Text(
            temperature == null
                ? '–'
                : UnitFormatUtils.formatTemperatureValue(
                    temperature,
                    context.temperatureUnit,
                  ),
            maxLines: 1,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (slice.windSpeedMs != null)
            Text(
              '${slice.windSpeedMs!.round()} m/s',
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          if (precipitation > 0)
            Text(
              '${precipitation.toStringAsFixed(1)} mm/h',
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _WindIndicator extends StatelessWidget {
  const _WindIndicator({required this.speedMs});

  final double speedMs;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final presentation = weatherWindPresentation(speedMs, t);
    final accent = switch (presentation.tone) {
      WeatherWindTone.normal => null,
      WeatherWindTone.warning => Colors.amber.shade800,
      WeatherWindTone.strong => Colors.deepOrange.shade600,
    };
    final color = accent ?? colorScheme.onSurfaceVariant;

    final fullLabel = '${presentation.label} · ${speedMs.round()} m/s';
    return Semantics(
      label: fullLabel,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var bar = 0; bar < 3; bar++)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Container(
                  width: 3,
                  height: 6 + bar * 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.5),
                    color: bar < presentation.filledBars
                        ? color
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Text(
              '${speedMs.round()} m/s',
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: accent == null ? null : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// (emoji, title, body) for a window verdict — used by the weather share
/// card, the home flight card, and the flight hub.
(String, String, String) verdictPresentation(WindowVerdict verdict, dynamic t) {
  return switch (verdict) {
    WindowVerdict.clearViews => ('☀️', t.verdictClearTitle, t.verdictClearBody),
    WindowVerdict.patchyClouds => (
      '⛅',
      t.verdictPatchyTitle,
      t.verdictPatchyBody,
    ),
    WindowVerdict.cloudCarpet => (
      '☁️',
      t.verdictCarpetTitle,
      t.verdictCarpetBody,
    ),
    WindowVerdict.overcast => (
      '🌫️',
      t.verdictOvercastTitle,
      t.verdictOvercastBody,
    ),
  };
}
