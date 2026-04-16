import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/route_poi_rank.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/map/layers/poi_style_config.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/poi_preview_bottom_sheet.dart';

class PoiHighlightsSection extends StatefulWidget {
  const PoiHighlightsSection({required this.poi, super.key});

  final List<RoutePoiSummary> poi;

  @override
  State<PoiHighlightsSection> createState() => _PoiHighlightsSectionState();
}

class _PoiHighlightsSectionState extends State<PoiHighlightsSection> {
  static const int _highlightsLimit = 8;
  static const double _chipMaxWidth = 190;

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final rankedPois = _rankedPois(widget.poi);
    final visiblePois = _showAll
        ? rankedPois
        : rankedPois.take(_highlightsLimit).toList(growable: false);
    final hasHiddenPois = rankedPois.length > visiblePois.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in visiblePois)
              _PoiChip(item: item, maxWidth: _chipMaxWidth),
          ],
        ),
        if (hasHiddenPois) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text(
                context.t.flight.info.showAllCount(count: rankedPois.length),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<RoutePoiSummary> _rankedPois(List<RoutePoiSummary> poi) {
    final filtered = poi
        .where((item) => item.name.trim().isNotEmpty)
        .toList(growable: false);
    final ranked = List<RoutePoiSummary>.from(filtered);
    ranked.sort((a, b) {
      final scoreDiff = _rankScore(b).compareTo(_rankScore(a));
      if (scoreDiff != 0) return scoreDiff;
      return a.name.compareTo(b.name);
    });
    return ranked;
  }

  int _rankScore(RoutePoiSummary poi) =>
      RoutePoiRank.baseScore(type: poi.type, sitelinks: poi.sitelinks);
}

class _PoiChip extends StatelessWidget {
  const _PoiChip({required this.item, required this.maxWidth});

  final RoutePoiSummary item;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final typeColor = PoiStyleConfig.colorFor(item.type);
    return ActionChip(
      backgroundColor: typeColor.withValues(alpha: 0.10),
      side: BorderSide(color: typeColor.withValues(alpha: 0.28)),
      shape: const StadiumBorder(),
      labelStyle: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(_iconAssetPathForType(item.type), width: 16, height: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onPressed: () async {
        await showPoiPreviewDialog(
          context: context,
          name: item.name,
          typeRaw: item.type.rawValue,
          qid: item.qid,
        );
      },
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelPadding: EdgeInsets.zero,
    );
  }

  String _iconAssetPathForType(FlightPoiType type) => switch (type) {
    FlightPoiType.city => 'assets/images/poi/city.png',
    FlightPoiType.river => 'assets/images/poi/river.png',
    FlightPoiType.island => 'assets/images/poi/island.png',
    FlightPoiType.airport => 'assets/images/poi/airport.png',
    FlightPoiType.mountain => 'assets/images/poi/mountain.png',
    FlightPoiType.lake => 'assets/images/poi/lake.png',
    FlightPoiType.volcano => 'assets/images/poi/volcano.png',
    FlightPoiType.pass => 'assets/images/poi/mountain.png',
    FlightPoiType.bay => 'assets/images/poi/bay.png',
    FlightPoiType.waterfall => 'assets/images/poi/waterfall.png',
    FlightPoiType.glacier => 'assets/images/poi/glacier.png',
    FlightPoiType.desert => 'assets/images/poi/desert.png',
    FlightPoiType.sea => 'assets/images/poi/sea.png',
    FlightPoiType.region => 'assets/images/poi/region.png',
    FlightPoiType.unknown => 'assets/images/poi/unknown.png',
  };
}
