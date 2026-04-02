import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_poi.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/section_card.dart';

class PoiSection extends StatelessWidget {
  const PoiSection({required this.poi, super.key});

  final List<FlightPoi> poi;

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      title: context.t.flight.info.pointsOfInterestTitle,
      child: poi.isEmpty
          ? Text(context.t.flight.info.noPoi)
          : Wrap(
              spacing: DsSpacing.xs,
              runSpacing: DsSpacing.xs,
              children: [
                for (final item in poi)
                  if (item.name.trim().isNotEmpty)
                    SelectionChip(
                      label: item.name,
                      onPressed: () => _openPoiDetails(context, item),
                    ),
              ],
            ),
    );
  }

  void _openPoiDetails(BuildContext context, FlightPoi item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PoiDetailsSheet(item: item),
    );
  }
}

class _PoiDetailsSheet extends StatelessWidget {
  const _PoiDetailsSheet({required this.item});

  final FlightPoi item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        0,
        DsSpacing.md,
        DsSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DsSpacing.xs),
          if (item.type.trim().isNotEmpty)
            Text(context.t.flight.info.poiType(type: item.type)),
          if (item.description.trim().isNotEmpty) ...[
            const SizedBox(height: DsSpacing.xs),
            Text(item.description),
          ],
          if (item.flyView.trim().isNotEmpty) ...[
            const SizedBox(height: DsSpacing.xs),
            Text(context.t.flight.info.poiFlyOver(view: item.flyView)),
          ],
          if (item.wiki.trim().isNotEmpty) ...[
            const SizedBox(height: DsSpacing.xs),
            SelectableText(item.wiki),
          ],
        ],
      ),
    );
  }
}
