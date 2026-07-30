import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_poi_type.dart';
import 'package:flymap/domain/entity/poi_wiki_preview.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/widgets/ds_chips.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/poi_preview_bottom_sheet.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/shared/tab_state_placeholder.dart';
import 'package:flymap/ui/screens/shared/poi_type_marker_asset.dart';
import 'package:flymap/utils/duration_format_utils.dart';
import 'package:latlong2/latlong.dart';

/// Places as a vertical corridor diagram: departure on top, a dashed road
/// down to the arrival, and every place as a stop in FLIGHT ORDER —
/// drawn on the TRUE side of the track (one cross-product per place), so
/// the left column literally is the left window. Type chips filter the
/// stops; the road and airports always remain.
class FlightPlacesScreen extends StatefulWidget {
  const FlightPlacesScreen({super.key});

  @override
  State<FlightPlacesScreen> createState() => _FlightPlacesScreenState();
}

class _FlightPlacesScreenState extends State<FlightPlacesScreen> {
  FlightPoiType? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.flight.hub.placesTitle)),
      body: SafeArea(
        child: BlocBuilder<FlightScreenCubit, FlightScreenState>(
          builder: (context, state) {
            final flight = switch (state) {
              FlightScreenLoaded(:final flight) => flight,
              FlightScreenError(:final flight?) => flight,
              _ => null,
            };
            if (flight == null) {
              return FlightTabStatePlaceholder(
                icon: Icons.place_outlined,
                text: context.t.flight.info.loadingRouteInformation,
              );
            }
            final stops = _buildStops(flight);
            if (stops.isEmpty) {
              return FlightTabStatePlaceholder(
                icon: Icons.place_outlined,
                text: context.t.flight.hub.noPlaces,
              );
            }
            return _CorridorDiagram(
              flight: flight,
              stops: stops,
              filter: _filter,
              onFilterChanged: (type) => setState(() => _filter = type),
            );
          },
        ),
      ),
    );
  }

  List<_PlaceStop> _buildStops(Flight flight) {
    final waypoints = flight.route.waypointLatLngs;
    final stops = <_PlaceStop>[
      for (final place in flight.info.poi)
        if (place.name.trim().isNotEmpty) _locate(place, waypoints),
    ]..sort((a, b) => a.progress.compareTo(b.progress));
    return stops;
  }

  /// Progress along the route (fallback: nearest waypoint) and the TRUE
  /// side of the track via the cross product of the local flight direction
  /// with the vector to the place. Positive = pilot's left -> drawn left.
  _PlaceStop _locate(RoutePoiSummary place, List<LatLng> waypoints) {
    var progress = place.routeProgress;
    if (waypoints.length < 2) {
      return _PlaceStop(
        place: place,
        progress: progress ?? 0.5,
        isLeft: false,
      );
    }
    if (progress == null) {
      var best = 0;
      var bestD2 = double.infinity;
      for (var i = 0; i < waypoints.length; i++) {
        final dx = waypoints[i].longitude - place.latLon.longitude;
        final dy = waypoints[i].latitude - place.latLon.latitude;
        final d2 = dx * dx + dy * dy;
        if (d2 < bestD2) {
          bestD2 = d2;
          best = i;
        }
      }
      progress = best / (waypoints.length - 1);
    }
    final index = (progress * (waypoints.length - 1)).floor().clamp(
      0,
      waypoints.length - 2,
    );
    final a = waypoints[index];
    final b = waypoints[index + 1];
    final dirX = b.longitude - a.longitude;
    final dirY = b.latitude - a.latitude;
    final toPlaceX = place.latLon.longitude - a.longitude;
    final toPlaceY = place.latLon.latitude - a.latitude;
    final cross = dirX * toPlaceY - dirY * toPlaceX;
    return _PlaceStop(place: place, progress: progress, isLeft: cross > 0);
  }
}

class _PlaceStop {
  const _PlaceStop({
    required this.place,
    required this.progress,
    required this.isLeft,
  });

  final RoutePoiSummary place;
  final double progress;
  final bool isLeft;
}

class _CorridorDiagram extends StatelessWidget {
  const _CorridorDiagram({
    required this.flight,
    required this.stops,
    required this.filter,
    required this.onFilterChanged,
  });

  final Flight flight;
  final List<_PlaceStop> stops;
  final FlightPoiType? filter;
  final ValueChanged<FlightPoiType?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t.flight.hub;
    final filtered = filter == null
        ? stops
        : stops.where((s) => s.place.type == filter).toList(growable: false);

    // Chips ordered by how much there is to see.
    final counts = <FlightPoiType, int>{};
    for (final stop in stops) {
      counts.update(stop.place.type, (v) => v + 1, ifAbsent: () => 1);
    }
    final types = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    final totalMinutes = _totalMinutes(flight);
    final rows = _buildRows(context, filtered, totalMinutes);

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SelectionChip(
                  label: '${t.filterAll} (${stops.length})',
                  selected: filter == null,
                  showCheckmark: false,
                  onPressed: () => onFilterChanged(null),
                ),
              ),
              for (final type in types)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SelectionChip(
                    label: '${_typeLabel(context, type)} (${counts[type]})',
                    selected: filter == type,
                    showCheckmark: false,
                    onPressed: () =>
                        onFilterChanged(filter == type ? null : type),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: rows.length,
            itemBuilder: (context, index) => rows[index],
          ),
        ),
      ],
    );
  }

  int _totalMinutes(Flight flight) {
    final displayBlockMinutes = flight.route.durations.displayBlockMinutes;
    return displayBlockMinutes > 0
        ? displayBlockMinutes
        : flight.info.routeCruiseMinutes;
  }

  List<Widget> _buildRows(
    BuildContext context,
    List<_PlaceStop> filtered,
    int totalMinutes,
  ) {
    final rows = <Widget>[
      _AirportNode(
        airportCode: flight.route.departure.displayCode,
        airportName: flight.route.departure.name,
        icon: Icons.flight_takeoff_rounded,
      ),
    ];

    // Quarter-time markers pinned on the road between the stops they fall
    // between — enough rhythm to make a 200-stop road scannable.
    final markerQuarters = totalMinutes > 0 ? [0.25, 0.5, 0.75] : <double>[];
    var nextMarker = 0;
    for (final stop in filtered) {
      while (nextMarker < markerQuarters.length &&
          stop.progress > markerQuarters[nextMarker]) {
        rows.add(
          _TimeMarker(
            label:
                '~${DurationFormatUtils.formatApprox(context, (totalMinutes * markerQuarters[nextMarker]).round()) ?? ''}',
          ),
        );
        nextMarker++;
      }
      rows.add(_StopRow(stop: stop));
    }
    // Markers past the last stop are dropped on purpose — a label on an
    // empty stretch of road right before the arrival adds nothing.

    rows.add(
      _AirportNode(
        airportCode: flight.route.arrival.displayCode,
        airportName: flight.route.arrival.name,
        icon: Icons.flight_land_rounded,
      ),
    );
    return rows;
  }

  String _typeLabel(BuildContext context, FlightPoiType type) {
    if (type == FlightPoiType.unknown) {
      return context.t.subscription.unknown;
    }
    final raw = type.rawValue.replaceAll('_', ' ');
    return raw
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1) : ''}',
        )
        .join(' ');
  }
}

/// Departure/arrival endpoint: the big circle the road hangs from.
class _AirportNode extends StatelessWidget {
  const _AirportNode({
    required this.airportCode,
    required this.airportName,
    required this.icon,
  });

  final String airportCode;
  final String airportName;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.onPrimary, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          airportCode,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          airportName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// One stop: road segment in the middle, the place on its true side.
class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop});

  final _PlaceStop stop;

  @override
  Widget build(BuildContext context) {
    final tile = _PlaceTile(place: stop.place, alignedRight: stop.isLeft);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: stop.isLeft ? tile : const SizedBox()),
          const _RoadSegment(withNode: true),
          Expanded(child: stop.isLeft ? const SizedBox() : tile),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.alignedRight});

  final RoutePoiSummary place;

  /// True when the tile sits LEFT of the road (content hugs the road).
  final bool alignedRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = ClipOval(
      child: Image.asset(
        PoiTypeMarkerAsset.iconPathFor(place.type),
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.place_outlined, size: 18),
      ),
    );
    final name = Flexible(
      child: Text(
        place.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignedRight ? TextAlign.end : TextAlign.start,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openPoiPreview(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: alignedRight
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: alignedRight
              ? [name, const SizedBox(width: 8), icon]
              : [icon, const SizedBox(width: 8), name],
        ),
      ),
    );
  }

  Future<void> _openPoiPreview(BuildContext context) async {
    await showPoiPreviewDialog(
      context: context,
      name: place.name,
      typeRaw: place.type.rawValue,
      qid: place.qid,
      actionMode: PoiPreviewActionMode.openOnly,
      preloadedPreview: PoiWikiPreview(
        qid: place.qid,
        title: place.name,
        summary: place.description,
        htmlContent: place.descriptionHtml,
        sourceUrl: place.wiki,
        languageCode: '',
      ),
    );
  }
}

/// A "~1h 20m" pill pinned on the road.
class _TimeMarker extends StatelessWidget {
  const _TimeMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      height: 36,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Row(
              children: [
                Expanded(child: SizedBox()),
                _RoadSegment(withNode: false),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashed road: a fixed-width column whose painter fills the row
/// height, so consecutive rows read as one continuous line.
class _RoadSegment extends StatelessWidget {
  const _RoadSegment({required this.withNode});

  final bool withNode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      child: CustomPaint(
        painter: _RoadPainter(
          color: colorScheme.outlineVariant,
          nodeColor: colorScheme.primary,
          withNode: withNode,
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({
    required this.color,
    required this.nodeColor,
    required this.withNode,
  });

  final Color color;
  final Color nodeColor;
  final bool withNode;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const dash = 6.0;
    const gap = 5.0;
    var y = 0.0;
    while (y < size.height) {
      final end = (y + dash).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dash + gap;
    }
    if (withNode) {
      final center = Offset(x, size.height / 2);
      canvas.drawCircle(center, 6, Paint()..color = nodeColor);
      canvas.drawCircle(
        center,
        3,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_RoadPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.nodeColor != nodeColor ||
      oldDelegate.withNode != withNode;
}
