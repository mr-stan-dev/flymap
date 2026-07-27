import 'package:flutter/widgets.dart';
import 'package:flymap/i18n/strings.g.dart';

class DurationFormatUtils {
  const DurationFormatUtils._();

  /// Approximate flight time for glanceable UI: rounded to 5 minutes (e.g.
  /// "2h 35m"), or null when there is no estimate. No "~" prefix — at small
  /// sizes it reads as a minus; the rounding alone signals an estimate.
  /// Shared by the home card and the route overview so both read identically.
  static String? formatApprox(BuildContext context, int minutes) {
    if (minutes <= 0) return null;
    final rounded = (minutes / 5).round() * 5;
    final timelineT = context.t.createFlight.overview.timeline;
    if (rounded < 60) return '$rounded ${timelineT.minuteUnit}';
    final h = rounded ~/ 60;
    final m = rounded % 60;
    if (m == 0) return '$h${timelineT.hourCompactUnit}';
    return '$h${timelineT.hourCompactUnit} $m${timelineT.minuteCompactUnit}';
  }
}
