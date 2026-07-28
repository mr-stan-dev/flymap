import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:flymap/domain/policy/route_region_timeline_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_route_map_card.dart';
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

    // The forecast is for the FLIGHT date — say so prominently, not just
    // via a fetch timestamp.
    final forecastDateLine = [
      t.forecastFor(
        date: TravelDateFormatUtils.formatShortDate(
          weather.departure.timeLocal,
        ),
      ),
      if (weather.isTimeEstimated) t.estimatedBadge,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.event_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                forecastDateLine,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _AirportWeatherCard(
                  label: t.departureLabel,
                  code: route?.departure.displayCode ?? '',
                  city: route?.departure.city ?? '',
                  weather: weather.departure,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AirportWeatherCard(
                  label: t.arrivalLabel,
                  code: route?.arrival.displayCode ?? '',
                  city: route?.arrival.city ?? '',
                  weather: weather.arrival,
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
            expectationLine: _expectationLine(context),
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

  /// "☀️ Clear after takeoff · ☁️ Cloud carpet over the Alps · …"
  String? _expectationLine(BuildContext context) {
    final t = context.t.createFlight.weather;
    final segments = FlightWeatherVerdictPolicy.segments(weather.samples);
    if (segments.length <= 1) return null;
    final route = state.flightRoute;
    final markers = route == null
        ? const <RouteRegionMarker>[]
        : RouteRegionTimelinePolicy.forFlight(
            regions: state.routeRegions,
            departureCountryCode: route.departure.countryCode,
            arrivalCountryCode: route.arrival.countryCode,
            totalRouteKm: route.distanceInKm,
            languageCode: LocaleSettings.currentLocale.languageCode,
          );

    String verdictWord(WindowVerdict verdict) => switch (verdict) {
      WindowVerdict.clearViews => t.expectClear,
      WindowVerdict.patchyClouds => t.expectPatchy,
      WindowVerdict.cloudCarpet => t.expectCarpet,
      WindowVerdict.overcast => t.expectOvercast,
    };

    String placePhrase(WeatherSegment segment) {
      for (final marker in markers) {
        if (marker.routeProgress >= segment.startProgress &&
            marker.routeProgress <= segment.endProgress) {
          return t.segmentOver(name: marker.name);
        }
      }
      if (segment.midProgress < 0.33) return t.segmentAfterTakeoff;
      if (segment.midProgress < 0.66) return t.segmentMidFlight;
      return t.segmentBeforeLanding;
    }

    return segments
        .map((segment) =>
            '${verdictWord(segment.verdict)} ${placePhrase(segment)}')
        .join(' · ');
  }
}

class _AirportWeatherCard extends StatelessWidget {
  const _AirportWeatherCard({
    required this.label,
    required this.code,
    required this.city,
    required this.weather,
  });

  final String label;
  final String code;
  final String city;
  final AirportWeather weather;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final temperature = weather.temperatureC;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                TravelDateFormatUtils.formatTime(weather.timeLocal),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            code,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (city.isNotEmpty)
            Text(
              city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _symbolEmoji(weather.symbolCode, weather.cloudCoverPercent),
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
          Row(
            children: [
              if (weather.windSpeedMs != null) ...[
                Icon(
                  Icons.air_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${weather.windSpeedMs!.round()} m/s',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if ((weather.precipitationMm ?? 0) > 0) ...[
                const SizedBox(width: 10),
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
            ],
          ),
        ],
      ),
    );
  }

  /// Native emoji (yellow sun, real clouds) instead of tinted icons.
  String _symbolEmoji(String? symbolCode, double? cloudCover) {
    final code = symbolCode ?? '';
    if (code.contains('thunder')) return '⛈️';
    if (code.contains('snow') || code.contains('sleet')) return '🌨️';
    if (code.contains('rain')) return '🌧️';
    if (code.contains('fog')) return '🌫️';
    if (code.startsWith('clearsky')) return '☀️';
    if (code.startsWith('fair')) return '🌤️';
    if (code.startsWith('partlycloudy')) return '⛅';
    if (code.startsWith('cloudy')) return '☁️';
    // No symbol (6h-block entries sometimes omit it): fall back to cover.
    final cover = cloudCover ?? 50;
    if (cover < 25) return '☀️';
    if (cover < 70) return '⛅';
    return '☁️';
  }
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.verdict, this.expectationLine});

  final WindowVerdict verdict;
  final String? expectationLine;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (emoji, title, body) = switch (verdict) {
      WindowVerdict.clearViews => (
        '☀️',
        t.verdictClearTitle,
        t.verdictClearBody,
      ),
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
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
          if (expectationLine != null) ...[
            const SizedBox(height: 8),
            Text(
              expectationLine!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
