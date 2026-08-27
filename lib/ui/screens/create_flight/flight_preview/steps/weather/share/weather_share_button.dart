import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/policy/domestic_route_policy.dart';
import 'package:flymap/ui/screens/flight_video/rendering/region_highlight_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/ui/screens/settings/date_display_format_context.dart';
import 'package:flymap/ui/screens/settings/temperature_unit_context.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';
import 'package:flymap/utils/unit_format_utils.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_renderer.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_service.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_symbols.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_wind_presentation.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';

/// Pro-only share entry for the weather step, rendered as an app-bar icon
/// button: image (story card) or video (one plane-flight loop,
/// hardware-encoded MP4) via the native sheet.
class WeatherShareButton extends StatefulWidget {
  const WeatherShareButton({
    required this.route,
    required this.weather,
    this.flightNumber,
    this.flightId,
    super.key,
  });

  final FlightRoute route;
  final FlightWeather weather;
  final String? flightNumber;

  /// Saved flight id, when sharing a stored flight. Lets the renderer pull the
  /// map base from the per-flight offline cache so the shared image/video
  /// still shows the satellite map in airplane mode. Null in the creation
  /// flow (no saved flight yet), where the base is fetched live.
  final String? flightId;

  @override
  State<WeatherShareButton> createState() => _WeatherShareButtonState();
}

class _WeatherShareButtonState extends State<WeatherShareButton> {
  static const _logger = Logger('WeatherShareButton');
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    // Guarded for widget tests without DI.
    if (!GetIt.I.isRegistered<WeatherShareService>()) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: t.share,
      onPressed: _isSharing ? null : _pickFormat,
      icon: _isSharing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.share_rounded),
    );
  }

  Future<void> _pickFormat() async {
    final t = context.t.createFlight.weather;
    final asVideo = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: Text(t.shareAsImage),
              onTap: () => Navigator.of(sheetContext).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.movie_rounded),
              title: Text(t.shareAsVideo),
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
          ],
        ),
      ),
    );
    if (asVideo == null || !mounted) return;
    await _share(asVideo: asVideo);
  }

  Future<void> _share({required bool asVideo}) async {
    final t = context.t.createFlight.weather;
    final service = GetIt.I.get<WeatherShareService>();
    final progress = ValueNotifier<double>(0);
    setState(() => _isSharing = true);
    // Origin for the iPad share popover.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;

    _showProgressDialog(progress, t.preparingShare);
    WeatherShareRenderer? renderer;
    try {
      renderer = await service.buildRenderer(
        route: widget.route,
        weather: widget.weather,
        data: _shareData(),
        flightId: widget.flightId,
      );
      final path = asVideo
          ? await service.exportVideo(
              renderer,
              onProgress: (value) => progress.value = value,
            )
          : await service.exportImage(renderer);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Share.shareXFiles([XFile(path)], sharePositionOrigin: origin);
      // Firebase-only volume metric; fire-and-forget so it can't affect the
      // share result.
      if (GetIt.I.isRegistered<AppAnalytics>()) {
        unawaited(
          GetIt.I.get<AppAnalytics>().log(
            WeatherShareEvent(
              asVideo ? WeatherShareFormat.video : WeatherShareFormat.image,
            ),
          ),
        );
      }
    } catch (e) {
      _logger.error('weather share failed: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.shareFailed)));
      }
    } finally {
      if (renderer != null) service.disposeRenderer(renderer);
      progress.dispose();
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showProgressDialog(ValueNotifier<double> progress, String title) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value == 0 ? null : value),
              const SizedBox(height: 16),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  WeatherShareData _shareData() {
    final t = context.t.createFlight.weather;
    final route = widget.route;
    final weather = widget.weather;
    // Event-handler context: read, not watch. The share card renders in the
    // user's own unit preference.
    final tempUnit = temperatureUnitFromSetting(
      context.read<SettingsCubit>().state.temperatureUnit,
    );
    final flightNumber = widget.flightNumber?.trim() ?? '';
    final dateFormat = dateDisplayFormatFromSetting(
      context.read<SettingsCubit>().state.dateDisplayFormat,
    );
    final date = TravelDateFormatUtils.formatShortDate(
      weather.departure.timeLocal,
      dateFormat,
    );
    // Country flags in the headline for cross-border flights only — same rule
    // as the other share cards.
    final crossBorder = !DomesticRoutePolicy.isDomestic(
      originCountryCode: route.departure.countryCode,
      destinationCountryCode: route.arrival.countryCode,
    );
    final depFlag = crossBorder
        ? RegionHighlightModel.flagEmoji(route.departure.countryCode)
        : null;
    final arrFlag = crossBorder
        ? RegionHighlightModel.flagEmoji(route.arrival.countryCode)
        : null;
    final depCode = depFlag == null
        ? route.departure.displayCode
        : '$depFlag ${route.departure.displayCode}';
    final arrCode = arrFlag == null
        ? route.arrival.displayCode
        : '$arrFlag ${route.arrival.displayCode}';
    return WeatherShareData(
      headline: '$depCode → $arrCode',
      subtitle: flightNumber.isEmpty ? date : '$flightNumber · $date',
      departure: _airport(
        route.departure,
        weather.departure,
        tempUnit,
        dateFormat,
      ),
      arrival: _airport(
        route.arrival,
        weather.arrival,
        tempUnit,
        dateFormat,
        isNextDay: _isNextDay(
          weather.departure.timeLocal,
          weather.arrival.timeLocal,
        ),
      ),
      attribution:
          '${t.attributionShare(provider: weather.attribution.providerName, license: weather.attribution.licenseName)}\n'
          '${weather.attribution.licenseUrl}',
      watermark: 'flymap.app',
    );
  }

  WeatherShareAirport _airport(
    Airport airport,
    AirportWeather weather,
    TemperatureUnit tempUnit,
    DateDisplayFormat dateFormat, {
    bool isNextDay = false,
  }) {
    final temperature = weather.temperatureC;
    final wind = weather.windSpeedMs;
    final windPresentation = wind == null
        ? null
        : weatherWindPresentation(wind, context.t.createFlight.weather);
    var dateText = TravelDateFormatUtils.formatShortDate(
      weather.timeLocal,
      dateFormat,
    );
    if (isNextDay) {
      dateText = '$dateText (${context.t.createFlight.weather.tomorrow})';
    }
    final normalizedCountryCode = airport.countryCode.trim().toUpperCase();
    return WeatherShareAirport(
      code: airport.displayCode,
      city: airport.city,
      countryCode: normalizedCountryCode,
      countryFlag: RegionHighlightModel.flagEmoji(normalizedCountryCode) ?? '',
      emoji: weatherSymbolEmoji(
        weather.symbolCode,
        weather.cloudCoverPercent,
        isDaytime: weatherIsDaytime(
          timeUtc: weather.timeUtc,
          utcOffsetMinutes: weather.utcOffsetMinutes,
          coordinate: airport.latLon,
        ),
        precipitationMm: weather.precipitationMm,
      ),
      temperatureText: temperature == null
          ? '–'
          : UnitFormatUtils.formatTemperatureValue(temperature, tempUnit),
      timeText: TravelDateFormatUtils.formatTime(weather.timeLocal),
      utcOffsetText: TravelDateFormatUtils.formatUtcOffset(
        weather.utcOffsetMinutes,
      ),
      dateText: dateText,
      windText: windPresentation == null
          ? null
          : '${windPresentation.label} · ${wind!.round()} m/s',
      windFilledBars: windPresentation?.filledBars ?? 0,
      windTone: windPresentation?.tone ?? WeatherWindTone.normal,
      precipitationText: (weather.precipitationMm ?? 0) > 0
          ? '${weather.precipitationMm!.toStringAsFixed(1)} mm/h'
          : null,
    );
  }

  bool _isNextDay(DateTime departure, DateTime arrival) {
    DateTime dateOnly(DateTime value) =>
        DateTime(value.year, value.month, value.day);
    return dateOnly(arrival).difference(dateOnly(departure)).inDays == 1;
  }
}
