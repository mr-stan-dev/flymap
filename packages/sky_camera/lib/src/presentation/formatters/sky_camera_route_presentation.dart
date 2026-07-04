import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';
import 'package:sky_camera/src/presentation/formatters/sky_camera_flag_emoji.dart';

class SkyCameraRoutePresentation {
  const SkyCameraRoutePresentation({
    required this.originDisplay,
    required this.destinationDisplay,
    required this.subtitle,
    required this.isDomestic,
  });

  factory SkyCameraRoutePresentation.fromSnapshot(
    SkyCameraOverlaySnapshot snapshot,
  ) {
    final originCountryCode = snapshot.originCountryCode.trim().toUpperCase();
    final destinationCountryCode = snapshot.destinationCountryCode
        .trim()
        .toUpperCase();
    final isDomestic = snapshot.isDomestic;
    final originCode = snapshot.originCode.trim();
    final destinationCode = snapshot.destinationCode.trim();
    return SkyCameraRoutePresentation(
      originDisplay: _airportDisplay(
        airportCode: originCode,
        countryCode: originCountryCode,
      ),
      destinationDisplay: _airportDisplay(
        airportCode: destinationCode,
        countryCode: destinationCountryCode,
      ),
      subtitle: _subtitle(
        snapshot: snapshot,
        isDomestic: isDomestic,
        originCountryCode: originCountryCode,
        destinationCountryCode: destinationCountryCode,
      ),
      isDomestic: isDomestic,
    );
  }

  final String originDisplay;
  final String destinationDisplay;
  final String? subtitle;
  final bool isDomestic;

  static String _airportDisplay({
    required String airportCode,
    required String countryCode,
  }) {
    final flag = skyCameraFlagEmoji(countryCode);
    return flag.isEmpty ? airportCode : '$flag $airportCode';
  }

  static String? _subtitle({
    required SkyCameraOverlaySnapshot snapshot,
    required bool isDomestic,
    required String originCountryCode,
    required String destinationCountryCode,
  }) {
    var subtitle = snapshot.routeLabel.trim().replaceAll('->', '→');
    if (subtitle.isEmpty) return null;
    if (isDomestic) {
      final segments = subtitle.split('→');
      if (segments.length == 2) {
        subtitle =
            '${_withoutCountryCode(segments[0], originCountryCode)} → '
            '${_withoutCountryCode(segments[1], destinationCountryCode)}';
      }
    }
    final normalized = subtitle.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final currentRoute = '${snapshot.originCode}→${snapshot.destinationCode}'
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();
    return normalized == currentRoute ? null : subtitle;
  }

  static String _withoutCountryCode(String value, String countryCode) {
    return value
        .trim()
        .replaceFirst(
          RegExp(
            ',\\s*${RegExp.escape(countryCode)}\\s*\$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }
}
