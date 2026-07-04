import 'package:flutter/material.dart';
import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';
import 'package:sky_camera/src/presentation/formatters/sky_camera_flag_emoji.dart';
import 'package:sky_camera/src/presentation/formatters/sky_camera_telemetry_formatter.dart';
import 'package:sky_camera/src/presentation/sky_camera_metrics_position.dart';
import 'package:sky_camera/src/presentation/sky_camera_strings.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_brand_mark.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_draggable_metrics_panel.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_metrics_panel.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_tech_strip.dart';

class SkyCameraOverlayView extends StatelessWidget {
  const SkyCameraOverlayView({
    required this.snapshot,
    required this.strings,
    required this.metricsPosition,
    required this.onMetricsPositionChanged,
    super.key,
  });

  final SkyCameraOverlaySnapshot snapshot;
  final SkyCameraStrings strings;
  final SkyCameraMetricsPosition metricsPosition;
  final ValueChanged<SkyCameraMetricsPosition> onMetricsPositionChanged;

  static const _bottomGradientHeightFactor = 0.28;
  static const _referenceWidth = 393.0;
  static const _referenceHeight = _referenceWidth * 16 / 9;

  @override
  Widget build(BuildContext context) {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: snapshot,
      strings: strings,
    );
    final showsMetrics = formatter.visibleMetricDisplays.isNotEmpty;
    final shouldShowRouteHeader = _shouldShowRouteHeader();
    final routeSubtitle = _routeSubtitle();
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: _referenceWidth,
        height: _referenceHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: constraints.maxHeight * 0.42,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xE60259DE), Color(0x000259DE)],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: constraints.maxHeight * _bottomGradientHeightFactor,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xFF232323),
                          Color(0x33232323),
                          Color(0x00232323),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkyCameraTechStrip(formatter: formatter),
                            if (formatter.shouldShowTechStrip)
                              const SizedBox(height: 18),
                            if (shouldShowRouteHeader)
                              _SkyCameraRouteHeader(
                                originCode: snapshot.originCode,
                                destinationCode: snapshot.destinationCode,
                                originCountryCode: snapshot.originCountryCode,
                                destinationCountryCode:
                                    snapshot.destinationCountryCode,
                                subtitle: routeSubtitle,
                              ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      if (showsMetrics)
                        SkyCameraDraggableMetricsPanel(
                          position: metricsPosition,
                          onChanged: onMetricsPositionChanged,
                          child: SkyCameraMetricsPanel(formatter: formatter),
                        ),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(child: SkyCameraBrandMark()),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _routeSubtitle() {
    final subtitle = snapshot.routeLabel.trim();
    if (subtitle.isEmpty) return null;
    final normalized = subtitle
        .replaceAll('->', '→')
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();
    final currentRoute = '${snapshot.originCode}→${snapshot.destinationCode}'
        .toUpperCase();
    if (normalized == currentRoute) {
      return null;
    }
    return subtitle;
  }

  bool _shouldShowRouteHeader() {
    return snapshot.originCode.trim().isNotEmpty ||
        snapshot.destinationCode.trim().isNotEmpty ||
        _routeSubtitle() != null;
  }
}

class _SkyCameraRouteHeader extends StatelessWidget {
  const _SkyCameraRouteHeader({
    required this.originCode,
    required this.destinationCode,
    required this.originCountryCode,
    required this.destinationCountryCode,
    required this.subtitle,
  });

  final String originCode;
  final String destinationCode;
  final String originCountryCode;
  final String destinationCountryCode;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final originFlag = skyCameraFlagEmoji(originCountryCode);
    final destinationFlag = skyCameraFlagEmoji(destinationCountryCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              if (originFlag.isNotEmpty) TextSpan(text: '$originFlag '),
              TextSpan(text: originCode),
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              if (destinationFlag.isNotEmpty)
                TextSpan(text: '$destinationFlag '),
              TextSpan(text: destinationCode),
            ],
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.05,
            shadows: [
              Shadow(
                color: Color(0x42000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.94),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 1.2,
              shadows: const [
                Shadow(
                  color: Color(0x42000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
