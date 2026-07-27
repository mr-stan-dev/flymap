import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/tokens/ds_brand_colors.dart';
import 'package:flymap/domain/policy/route_region_premium_gate_policy.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_grouping.dart';
import 'package:flymap/ui/screens/shared/route_timeline/widgets/airport_timeline_card.dart';
import 'package:flymap/ui/screens/shared/route_timeline/widgets/region_group_timeline_card.dart';
import 'package:flymap/ui/screens/shared/route_timeline/widgets/timeline_premium_gate_card.dart';

class RouteTimelineWidget extends StatelessWidget {
  const RouteTimelineWidget({
    required this.route,
    required this.regions,
    required this.isProUser,
    required this.cruiseSpeedKmh,
    required this.blockMinutes,
    required this.onPremiumGateTap,
    this.currentRegionId,
    this.lastVisitedRegionId,
    this.onOpenRegion,
    super.key,
  });

  final FlightRoute route;
  final List<RouteRegion> regions;
  final bool isProUser;
  final int cruiseSpeedKmh;
  final int blockMinutes;
  final VoidCallback onPremiumGateTap;
  final String? currentRegionId;
  final String? lastVisitedRegionId;
  final ValueChanged<RouteRegion>? onOpenRegion;

  @override
  Widget build(BuildContext context) {
    final orderedByDistance = RouteRegionPremiumGatePolicy.orderByDistance(
      regions,
    );
    final gateDecision = RouteRegionPremiumGatePolicy.evaluate(
      orderedRegions: orderedByDistance,
      isProUser: isProUser,
    );
    final groups = RouteTimelineGrouping.groupByTimeline(
      regions,
      cruiseSpeedKmh: cruiseSpeedKmh,
      maxTimelineMinutes: route.isHistoricalTrack ? blockMinutes : null,
      routeDistanceKm: route.distanceInKm,
      blockMinutes: blockMinutes,
      useTotalDurationProportion: !route.isHistoricalTrack,
    );
    final entriesBuild = _buildEntries(groups, gateDecision: gateDecision);
    final entries = entriesBuild.entries;
    final currentEntryIndex = _findEntryIndexByRegionId(
      entries,
      regionId: currentRegionId,
      premiumRegionIds: entriesBuild.premiumRegionIds,
      premiumGateIndex: entriesBuild.premiumGateIndex,
    );
    final visitedEntryIndex =
        currentEntryIndex ??
        _findEntryIndexByRegionId(
          entries,
          regionId: lastVisitedRegionId,
          premiumRegionIds: entriesBuild.premiumRegionIds,
          premiumGateIndex: entriesBuild.premiumGateIndex,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < entries.length; index++)
          _RouteTimelineRow(
            timingLabel: _buildMinuteLabel(context, entries[index]),
            isPremiumGateRow:
                entries[index].kind == _RouteTimelineEntryKind.premiumGate,
            isFirst: index == 0,
            isLast: index == entries.length - 1,
            pointState: _pointState(
              index: index,
              currentEntryIndex: currentEntryIndex,
              visitedEntryIndex: visitedEntryIndex,
            ),
            lineAboveState: _lineAboveState(
              index: index,
              currentEntryIndex: currentEntryIndex,
              visitedEntryIndex: visitedEntryIndex,
            ),
            lineBelowState: _lineBelowState(
              index: index,
              currentEntryIndex: currentEntryIndex,
              visitedEntryIndex: visitedEntryIndex,
            ),
            card: _buildCard(context, entries[index]),
          ),
      ],
    );
  }

  _TimelineEntriesBuildResult _buildEntries(
    List<RouteTimelineRegionGroup> groups, {
    required RouteRegionPremiumGateDecision gateDecision,
  }) {
    final arrivalMinutes = RouteTimelineGrouping.arrivalMinutes(
      routeDistanceKm: route.distanceInKm,
      blockMinutes: blockMinutes,
      cruiseSpeedKmh: cruiseSpeedKmh,
      groups: groups,
      blockMinutesIsAuthoritative: route.isHistoricalTrack,
    );

    if (!gateDecision.isGated) {
      return _TimelineEntriesBuildResult(
        entries: [
          _RouteTimelineEntry.departure(route.departure),
          ...groups.map(_RouteTimelineEntry.group),
          _RouteTimelineEntry.arrival(
            route.arrival,
            minuteFromDeparture: arrivalMinutes,
          ),
        ],
        premiumRegionIds: gateDecision.premiumRegionIds,
      );
    }

    final hiddenRegionIds = gateDecision.premiumRegionIds;
    var premiumGateInserted = false;
    final entries = <_RouteTimelineEntry>[
      _RouteTimelineEntry.departure(route.departure),
    ];
    for (final group in groups) {
      final visibleRegions = group.regions
          .where((region) => !hiddenRegionIds.contains(region.qid))
          .toList(growable: false);
      final hasHiddenRegions = group.regions.length != visibleRegions.length;
      if (visibleRegions.isNotEmpty) {
        entries.add(
          _RouteTimelineEntry.group(
            RouteTimelineRegionGroup(
              distanceFromDepartureKm: group.distanceFromDepartureKm,
              minuteFromDeparture: group.minuteFromDeparture,
              regions: visibleRegions,
            ),
          ),
        );
      }
      if (!premiumGateInserted && hasHiddenRegions) {
        premiumGateInserted = true;
        entries.add(
          _RouteTimelineEntry.premiumGate(
            minuteFromDeparture: group.minuteFromDeparture,
          ),
        );
      }
    }
    if (!premiumGateInserted && hiddenRegionIds.isNotEmpty) {
      premiumGateInserted = true;
      entries.add(_RouteTimelineEntry.premiumGate(minuteFromDeparture: 0));
    }
    entries.add(
      _RouteTimelineEntry.arrival(
        route.arrival,
        minuteFromDeparture: arrivalMinutes,
      ),
    );
    final premiumGateIndex = entries.indexWhere(
      (entry) => entry.kind == _RouteTimelineEntryKind.premiumGate,
    );
    return _TimelineEntriesBuildResult(
      entries: entries,
      premiumRegionIds: hiddenRegionIds,
      premiumGateIndex: premiumGateInserted && premiumGateIndex >= 0
          ? premiumGateIndex
          : null,
    );
  }

  int? _findEntryIndexByRegionId(
    List<_RouteTimelineEntry> entries, {
    required String? regionId,
    required Set<String> premiumRegionIds,
    required int? premiumGateIndex,
  }) {
    if (regionId == null || regionId.isEmpty) return null;
    if (premiumRegionIds.contains(regionId) && premiumGateIndex != null) {
      return premiumGateIndex;
    }
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.kind != _RouteTimelineEntryKind.group) continue;
      final group = entry.regionGroup;
      if (group == null) continue;
      final found = group.regions.any((region) => region.qid == regionId);
      if (found) return i;
    }
    return null;
  }

  _RouteTimelinePointState _pointState({
    required int index,
    required int? currentEntryIndex,
    required int? visitedEntryIndex,
  }) {
    if (currentEntryIndex != null) {
      if (index < currentEntryIndex) return _RouteTimelinePointState.past;
      if (index == currentEntryIndex) return _RouteTimelinePointState.current;
      return _RouteTimelinePointState.future;
    }
    if (visitedEntryIndex != null) {
      return index <= visitedEntryIndex
          ? _RouteTimelinePointState.past
          : _RouteTimelinePointState.future;
    }
    return _RouteTimelinePointState.future;
  }

  _RouteTimelinePointState _lineAboveState({
    required int index,
    required int? currentEntryIndex,
    required int? visitedEntryIndex,
  }) {
    if (currentEntryIndex != null) {
      return index <= currentEntryIndex
          ? _RouteTimelinePointState.past
          : _RouteTimelinePointState.future;
    }
    if (visitedEntryIndex != null) {
      return index <= visitedEntryIndex
          ? _RouteTimelinePointState.past
          : _RouteTimelinePointState.future;
    }
    return _RouteTimelinePointState.future;
  }

  _RouteTimelinePointState _lineBelowState({
    required int index,
    required int? currentEntryIndex,
    required int? visitedEntryIndex,
  }) {
    if (currentEntryIndex != null) {
      return index < currentEntryIndex
          ? _RouteTimelinePointState.past
          : _RouteTimelinePointState.future;
    }
    if (visitedEntryIndex != null) {
      return index < visitedEntryIndex
          ? _RouteTimelinePointState.past
          : _RouteTimelinePointState.future;
    }
    return _RouteTimelinePointState.future;
  }

  Widget _buildCard(BuildContext context, _RouteTimelineEntry entry) {
    switch (entry.kind) {
      case _RouteTimelineEntryKind.departure:
        return AirportTimelineCard(airport: entry.airport!);
      case _RouteTimelineEntryKind.arrival:
        return AirportTimelineCard(airport: entry.airport!);
      case _RouteTimelineEntryKind.group:
        final onOpenRegion = this.onOpenRegion;
        return RegionGroupTimelineCard(
          group: entry.regionGroup!,
          onOpenRegion: onOpenRegion,
        );
      case _RouteTimelineEntryKind.premiumGate:
        final t = context.t;
        return TimelinePremiumGateCard(
          title: t.flight.route.premiumGateTitle,
          description: t.flight.route.premiumGateBodyWithCount(
            count: regions.length,
          ),
          ctaLabel: t.flight.route.premiumGateCta,
          onTap: onPremiumGateTap,
        );
    }
  }

  _TimingLabel _buildMinuteLabel(
    BuildContext context,
    _RouteTimelineEntry entry,
  ) {
    // Airports get words ("Take off" / "Land") instead of raw minutes — "0m"
    // says nothing, and the total duration already lives in the header.
    final timelineT = context.t.createFlight.overview.timeline;
    switch (entry.kind) {
      case _RouteTimelineEntryKind.departure:
        return _wordLabel(timelineT.takeOffTimeline);
      case _RouteTimelineEntryKind.arrival:
        return _wordLabel(timelineT.land);
      case _RouteTimelineEntryKind.group:
      case _RouteTimelineEntryKind.premiumGate:
        return _formatTimingLabel(context, entry.minuteFromDeparture);
    }
  }

  _TimingLabel _wordLabel(String word) {
    final lines = word.split('\n');
    if (lines.length > 1) {
      return _TimingLabel.twoLines(
        firstLine: _TimingLine(unit: lines[0]),
        secondLine: _TimingLine(unit: lines[1]),
      );
    }
    return _TimingLabel.single(_TimingLine(unit: word));
  }

  _TimingLabel _formatTimingLabel(BuildContext context, int? minutesRaw) {
    final minutes = minutesRaw ?? 0;
    final timelineT = context.t.createFlight.overview.timeline;
    final minuteUnit = timelineT.minuteCompactUnit;
    final hourUnit = timelineT.hourCompactUnit;
    if (minutes <= 0) {
      return _TimingLabel.single(_TimingLine(value: '0', unit: minuteUnit));
    }
    if (minutes < 60) {
      return _TimingLabel.single(
        _TimingLine(value: '$minutes', unit: minuteUnit),
      );
    }
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return _TimingLabel.twoLines(
      firstLine: _TimingLine(value: '$h', unit: hourUnit),
      secondLine: _TimingLine(value: '$m', unit: minuteUnit),
    );
  }
}

enum _RouteTimelineEntryKind { departure, group, premiumGate, arrival }

class _RouteTimelineEntry {
  const _RouteTimelineEntry._({
    required this.kind,
    required this.minuteFromDeparture,
    this.airport,
    this.regionGroup,
  });

  final _RouteTimelineEntryKind kind;
  final int minuteFromDeparture;
  final Airport? airport;
  final RouteTimelineRegionGroup? regionGroup;

  factory _RouteTimelineEntry.departure(Airport airport) {
    return _RouteTimelineEntry._(
      kind: _RouteTimelineEntryKind.departure,
      minuteFromDeparture: 0,
      airport: airport,
    );
  }

  factory _RouteTimelineEntry.group(RouteTimelineRegionGroup group) {
    return _RouteTimelineEntry._(
      kind: _RouteTimelineEntryKind.group,
      minuteFromDeparture: group.minuteFromDeparture,
      regionGroup: group,
    );
  }

  factory _RouteTimelineEntry.arrival(
    Airport airport, {
    required int minuteFromDeparture,
  }) {
    return _RouteTimelineEntry._(
      kind: _RouteTimelineEntryKind.arrival,
      minuteFromDeparture: minuteFromDeparture,
      airport: airport,
    );
  }

  factory _RouteTimelineEntry.premiumGate({required int minuteFromDeparture}) {
    return _RouteTimelineEntry._(
      kind: _RouteTimelineEntryKind.premiumGate,
      minuteFromDeparture: minuteFromDeparture,
    );
  }
}

class _TimelineEntriesBuildResult {
  const _TimelineEntriesBuildResult({
    required this.entries,
    required this.premiumRegionIds,
    this.premiumGateIndex,
  });

  final List<_RouteTimelineEntry> entries;
  final Set<String> premiumRegionIds;
  final int? premiumGateIndex;
}

enum _RouteTimelinePointState { past, current, future }

class _RouteTimelineRow extends StatelessWidget {
  const _RouteTimelineRow({
    required this.timingLabel,
    required this.isPremiumGateRow,
    required this.isFirst,
    required this.isLast,
    required this.pointState,
    required this.lineAboveState,
    required this.lineBelowState,
    required this.card,
  });

  static const double _dotSize = 14.0;
  static const double _railWidth = 20.0;

  final _TimingLabel timingLabel;
  final bool isPremiumGateRow;
  final bool isFirst;
  final bool isLast;
  final _RouteTimelinePointState pointState;
  final _RouteTimelinePointState lineAboveState;
  final _RouteTimelinePointState lineBelowState;
  final Widget card;

  @override
  Widget build(BuildContext context) {
    final futureColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.35);
    final passedColor = Theme.of(context).colorScheme.primary;
    const currentColor = Color(0xFF22C55E);

    Color colorFor(_RouteTimelinePointState state) {
      switch (state) {
        case _RouteTimelinePointState.past:
          return passedColor;
        case _RouteTimelinePointState.current:
          return currentColor;
        case _RouteTimelinePointState.future:
          return futureColor;
      }
    }

    final pointColor = colorFor(pointState);
    final colorScheme = Theme.of(context).colorScheme;
    final digitStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      height: 1.0,
      color: colorScheme.onSurfaceVariant,
    );
    final unitStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.0,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
    );
    final timingMaxWidth = _maxTimingRailWidth(
      context,
      digitStyle: digitStyle,
      unitStyle: unitStyle,
    );

    final dot = isPremiumGateRow
        ? _TimelinePremiumGateMarker(
            borderColor: DsBrandColors.proAmber,
            fillColor: Theme.of(context).colorScheme.surface,
          )
        : pointState == _RouteTimelinePointState.current
        ? _PulsingTimelineDot(color: pointColor)
        : Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: pointColor, width: 2),
            ),
          );

    return CustomPaint(
      painter: _TimelineLinePainter(
        lineAboveColor: isFirst ? Colors.transparent : colorFor(lineAboveState),
        lineBelowColor: isLast ? Colors.transparent : colorFor(lineBelowState),
        railCenterX: timingMaxWidth + 8 + _railWidth / 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: timingMaxWidth,
            child: isPremiumGateRow
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerRight,
                    child: _TimingLabelText(
                      label: timingLabel,
                      digitStyle: digitStyle,
                      unitStyle: unitStyle,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _railWidth,
            child: Center(
              child: isPremiumGateRow
                  ? dot
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: dot,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: card,
            ),
          ),
        ],
      ),
    );
  }

  double _maxTimingRailWidth(
    BuildContext context, {
    TextStyle? digitStyle,
    TextStyle? unitStyle,
  }) {
    final textDirection = Directionality.of(context);
    final painter = TextPainter(
      textDirection: textDirection,
      text: TextSpan(
        children: [
          TextSpan(text: '88', style: digitStyle),
          TextSpan(text: 'h', style: unitStyle),
        ],
      ),
    )..layout();
    return painter.width.ceilToDouble() + 2;
  }
}

class _TimelineLinePainter extends CustomPainter {
  const _TimelineLinePainter({
    required this.lineAboveColor,
    required this.lineBelowColor,
    required this.railCenterX,
  });

  final Color lineAboveColor;
  final Color lineBelowColor;
  final double railCenterX;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const strokeWidth = 2.0;

    if (lineAboveColor != Colors.transparent) {
      canvas.drawLine(
        Offset(railCenterX, 0),
        Offset(railCenterX, centerY - _RouteTimelineRow._dotSize / 2),
        Paint()
          ..color = lineAboveColor
          ..strokeWidth = strokeWidth,
      );
    }
    if (lineBelowColor != Colors.transparent) {
      canvas.drawLine(
        Offset(railCenterX, centerY + _RouteTimelineRow._dotSize / 2),
        Offset(railCenterX, size.height),
        Paint()
          ..color = lineBelowColor
          ..strokeWidth = strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_TimelineLinePainter oldDelegate) {
    return oldDelegate.lineAboveColor != lineAboveColor ||
        oldDelegate.lineBelowColor != lineBelowColor ||
        oldDelegate.railCenterX != railCenterX;
  }
}

class _TimingLabelText extends StatelessWidget {
  const _TimingLabelText({
    required this.label,
    required this.digitStyle,
    required this.unitStyle,
  });

  final _TimingLabel label;
  final TextStyle? digitStyle;
  final TextStyle? unitStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _line(label.firstLine),
        if (label.secondLine != null) ...[
          const SizedBox(height: 1),
          _line(label.secondLine!),
        ],
      ],
    );
  }

  Widget _line(_TimingLine line) {
    return Text.rich(
      TextSpan(
        children: [
          if (line.value.isNotEmpty)
            TextSpan(text: line.value, style: digitStyle),
          if (line.unit.isNotEmpty) TextSpan(text: line.unit, style: unitStyle),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      textAlign: TextAlign.right,
    );
  }
}

class _TimingLabel {
  const _TimingLabel.single(_TimingLine line)
    : firstLine = line,
      secondLine = null;

  const _TimingLabel.twoLines({
    required this.firstLine,
    required this.secondLine,
  });

  final _TimingLine firstLine;
  final _TimingLine? secondLine;
}

class _TimingLine {
  const _TimingLine({this.value = '', this.unit = ''});

  final String value;
  final String unit;
}

class _PulsingTimelineDot extends StatefulWidget {
  const _PulsingTimelineDot({required this.color});

  final Color color;

  @override
  State<_PulsingTimelineDot> createState() => _PulsingTimelineDotState();
}

class _PulsingTimelineDotState extends State<_PulsingTimelineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.15 + (_controller.value * 0.55);
        final scale = 1 + (_controller.value * 0.12);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: pulse),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelinePremiumGateMarker extends StatelessWidget {
  const _TimelinePremiumGateMarker({
    required this.borderColor,
    required this.fillColor,
  });

  final Color borderColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _RouteTimelineRow._dotSize,
      height: (_RouteTimelineRow._dotSize * 3) + 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(),
          const SizedBox(height: 2),
          _dot(),
          const SizedBox(height: 2),
          _dot(),
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: _RouteTimelineRow._dotSize,
      height: _RouteTimelineRow._dotSize,
      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
    );
  }
}
