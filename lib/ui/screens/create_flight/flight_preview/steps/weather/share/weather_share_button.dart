import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
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
    required this.verdictEmoji,
    required this.verdictTitle,
    this.flightNumber,
    this.flightId,
    super.key,
  });

  final FlightRoute route;
  final FlightWeather weather;
  final String verdictEmoji;
  final String verdictTitle;
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
    final date = TravelDateFormatUtils.formatShortDate(
      weather.departure.timeLocal,
      dateDisplayFormatFromSetting(
        context.read<SettingsCubit>().state.dateDisplayFormat,
      ),
    );
    return WeatherShareData(
      headline: '${route.departure.displayCode} → ${route.arrival.displayCode}',
      subtitle: flightNumber.isEmpty ? date : '$flightNumber · $date',
      departure: _airport(
        t.departureLabel,
        route.departure.displayCode,
        route.departure.city,
        weather.departure,
        weather.isTimeEstimated,
        tempUnit,
      ),
      arrival: _airport(
        t.arrivalLabel,
        route.arrival.displayCode,
        route.arrival.city,
        weather.arrival,
        weather.isTimeEstimated,
        tempUnit,
      ),
      verdictEmoji: widget.verdictEmoji,
      verdictTitle: widget.verdictTitle,
      watermark: 'flymap.app',
    );
  }

  WeatherShareAirport _airport(
    String label,
    String code,
    String city,
    AirportWeather weather,
    bool isTimeEstimated,
    TemperatureUnit tempUnit,
  ) {
    final temperature = weather.temperatureC;
    return WeatherShareAirport(
      label: label,
      code: code,
      city: city,
      emoji: weatherSymbolEmoji(weather.symbolCode, weather.cloudCoverPercent),
      temperatureText: temperature == null
          ? '–'
          : UnitFormatUtils.formatTemperatureValue(temperature, tempUnit),
      timeText: isTimeEstimated
          ? null
          : TravelDateFormatUtils.formatTime(weather.timeLocal),
    );
  }
}
