import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_route_map_card.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_symbols.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';

/// Dedicated weather step: route overview -> WEATHER -> Wikipedia articles.
///
/// Hero: the real static route map with Windy-style semi-transparent cloud
/// fields at the overhead-time samples (Pro; free sees the map + a lock).
/// Below: the window verdict with the per-segment expectation line, and the
/// two airport forecast cards.
class FlightSearchWeatherStep extends StatelessWidget {
  const FlightSearchWeatherStep({
    required this.state,
    required this.isProUser,
    required this.onRetry,
    required this.onContinue,
    required this.onPremiumGateTap,
    super.key,
  });

  final FlightPreviewState state;
  final bool isProUser;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final VoidCallback onPremiumGateTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final weather = state.flightWeather;

    final Widget body;
    if (state.isWeatherLoading) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(t.loading, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    } else if (weather == null) {
      body = Center(
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
                t.loadFailed,
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
    } else {
      body = _WeatherContent(
        state: state,
        weather: weather,
        isProUser: isProUser,
        onPremiumGateTap: onPremiumGateTap,
      );
    }

    return Column(
      children: [
        Expanded(child: body),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: context.t.common.kContinue,
              onPressed: onContinue,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({
    required this.state,
    required this.weather,
    required this.isProUser,
    required this.onPremiumGateTap,
  });

  final FlightPreviewState state;
  final FlightWeather weather;
  final bool isProUser;
  final VoidCallback onPremiumGateTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final verdict = FlightWeatherVerdictPolicy.overallVerdict(weather.samples);
    final route = state.flightRoute;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _AirportWeatherCard(
                  code: route?.departure.displayCode ?? '',
                  city: route?.departure.city ?? '',
                  countryCode: route?.departure.countryCode ?? '',
                  weather: weather.departure,
                  showTime: !weather.isTimeEstimated,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AirportWeatherCard(
                  code: route?.arrival.displayCode ?? '',
                  city: route?.arrival.city ?? '',
                  countryCode: route?.arrival.countryCode ?? '',
                  weather: weather.arrival,
                  showTime: !weather.isTimeEstimated,
                  // Derived from the noon estimate when no time is known —
                  // a guess, so it is not shown either.
                  isNextDay: _arrivalIsNextDay && !weather.isTimeEstimated,
                ),
              ),
            ],
          ),
        ),
        if (route != null && weather.samples.isNotEmpty) ...[
          const SizedBox(height: 14),
          WeatherRouteMapCard(
            route: route,
            samples: weather.samples,
            areaSamples: weather.areaSamples,
            isProUser: isProUser,
          ),
          if (!isProUser) ...[
            const SizedBox(height: 10),
            PremiumButton(
              label: context.t.common.upgrade,
              icon: Icons.workspace_premium_rounded,
              onPressed: onPremiumGateTap,
            ),
          ],
        ],
        if (weather.samples.isNotEmpty) ...[
          const SizedBox(height: 14),
          _VerdictBanner(
            verdict: verdict,
            expectationItems: _expectationItems(context),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          '${t.updatedAt(time: TravelDateFormatUtils.formatTime(weather.fetchedAt))}'
          ' · ${t.hedge}\n${t.attribution}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
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

  /// Wind warnings only, in flight order: a windy takeoff opens the list,
  /// a windy landing closes it; calm stays silent (the card gauges say so).
  ///
  /// Deliberately NOT a per-region cloud/rain breakdown: real forecasts
  /// oscillate, so long routes produced 6-8 rows, and the coarse place
  /// vocabulary collapsed distinct stretches into identical labels
  /// ("before landing" x3) that read as contradictions. The map is the
  /// honest picture of that variability; text at this granularity isn't.
  List<ExpectationItem> _expectationItems(BuildContext context) {
    final t = context.t.createFlight.weather;
    final route = state.flightRoute;
    final departureWind = weather.departure.windSpeedMs;
    final arrivalWind = weather.arrival.windSpeedMs;
    final windyDeparture =
        departureWind != null && departureWind >= windyThresholdMs;
    final windyArrival = arrivalWind != null && arrivalWind >= windyThresholdMs;

    return [
      if (windyDeparture)
        ExpectationItem(
          '💨',
          t.windTakeoff(
            city: _windPlace(route?.departure.city, route?.departure.displayCode),
            speed: '${departureWind.round()}',
          ),
        ),
      if (windyArrival)
        ExpectationItem(
          '💨',
          t.windLanding(
            city: _windPlace(route?.arrival.city, route?.arrival.displayCode),
            speed: '${arrivalWind.round()}',
          ),
        ),
    ];
  }

  String _windPlace(String? city, String? code) {
    final trimmed = city?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return code ?? '';
  }
}

/// One row of the verdict card's timeline list.
class ExpectationItem {
  const ExpectationItem(this.emoji, this.text);

  final String emoji;
  final String text;
}

/// Wind bands (m/s) shared by the airport-card indicator and the verdict
/// timeline: below [breezyThresholdMs] reads as calm/light (smooth ride),
/// from [windyThresholdMs] it is worth a warning.
const double breezyThresholdMs = 5;
const double windyThresholdMs = 8;
const double strongWindThresholdMs = 14;

class _AirportWeatherCard extends StatelessWidget {
  const _AirportWeatherCard({
    required this.code,
    required this.city,
    required this.countryCode,
    required this.weather,
    this.showTime = true,
    this.isNextDay = false,
  });

  final String code;
  final String city;
  final String countryCode;
  final AirportWeather weather;

  /// False when the flight has no scheduled time — the internal noon
  /// estimate must never be displayed as a departure time.
  final bool showTime;

  /// Arrival lands on the day after departure — mark it "(tomorrow)".
  final bool isNextDay;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final temperature = weather.temperatureC;
    final flagCode = countryCode.trim().toUpperCase();

    var dateLine = TravelDateFormatUtils.formatShortDate(weather.timeLocal);
    if (isNextDay) dateLine = '$dateLine (${t.tomorrow})';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Elevated tone + hairline border: reads as a card on both themes
        // (surfaceContainerLow vanished against the dark background).
        color: colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No departure/arrival captions: position (left/right card) and
          // the times say it; the width goes to the code + zoned time.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  code,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showTime)
                    Text.rich(
                      TextSpan(
                        text: TravelDateFormatUtils.formatTime(
                          weather.timeLocal,
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          if (_utcOffsetLabel != null)
                            TextSpan(
                              text: ' ${_utcOffsetLabel!}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  Text(
                    dateLine,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (city.isNotEmpty)
            Row(
              children: [
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                weatherSymbolEmoji(
                  weather.symbolCode,
                  weather.cloudCoverPercent,
                ),
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 10),
              Text(
                temperature == null ? '–' : '${temperature.round()}°',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 8),
          if (weather.windSpeedMs != null)
            _WindIndicator(speedMs: weather.windSpeedMs!),
          if ((weather.precipitationMm ?? 0) > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.umbrella_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${weather.precipitationMm!.toStringAsFixed(1)} mm',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// "GMT+2" / "GMT+5:30" from the forecast's UTC offset. Omitted at offset
  /// zero: the entity uses 0 for "unknown", so a bare time is more honest
  /// than a possibly-wrong "GMT".
  String? get _utcOffsetLabel {
    final minutes = weather.utcOffsetMinutes;
    if (minutes == 0) return null;
    final sign = minutes < 0 ? '-' : '+';
    final absolute = minutes.abs();
    final hours = absolute ~/ 60;
    final rest = absolute % 60;
    final restText = rest == 0 ? '' : ':${rest.toString().padLeft(2, '0')}';
    return 'GMT$sign$hours$restText';
  }
}

/// Wind strength at a glance: three signal-style bars fill and warm up in
/// color as the wind picks up, next to a qualitative label and the m/s
/// value — "is my drink safe on the tray" beats a bare number.
class _WindIndicator extends StatelessWidget {
  const _WindIndicator({required this.speedMs});

  final double speedMs;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (label, filledBars, Color? accent) = switch (speedMs) {
      < 2 => (t.windCalm, 1, null),
      < breezyThresholdMs => (t.windLight, 1, null),
      < windyThresholdMs => (t.windBreezy, 2, null),
      < strongWindThresholdMs => (t.windWindy, 3, Colors.amber.shade800),
      _ => (t.windStrong, 3, Colors.deepOrange.shade600),
    };
    final color = accent ?? colorScheme.onSurfaceVariant;

    return Row(
      children: [
        for (var bar = 0; bar < 3; bar++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: 3,
              height: 6 + bar * 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                color: bar < filledBars
                    ? color
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
              ),
            ),
          ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$label · ${speedMs.round()} m/s',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: accent == null ? null : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({
    required this.verdict,
    this.expectationItems = const <ExpectationItem>[],
  });

  final WindowVerdict verdict;

  /// Timeline-ordered key points; when present they replace the generic
  /// body sentence — a scannable list instead of a prose paragraph.
  final List<ExpectationItem> expectationItems;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (emoji, title, body) = verdictPresentation(verdict, t);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (expectationItems.isEmpty) ...[
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodyMedium),
          ] else
            for (final item in expectationItems) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

/// (emoji, title, body) for a window verdict — shared by the banner and
/// the weather share card.
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
