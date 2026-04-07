import 'package:flutter/material.dart';
import 'package:flymap/entity/poi_wiki_preview.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/poi_preview_bottom_sheet.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/section_card.dart';

class PoiSection extends StatelessWidget {
  const PoiSection({required this.poi, super.key});

  final List<RoutePoiSummary> poi;

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

  Future<void> _openPoiDetails(
    BuildContext context,
    RoutePoiSummary item,
  ) async {
    await showPoiPreviewDialog(
      context: context,
      name: item.name,
      typeRaw: item.type.rawValue,
      qid: item.qid,
      actionMode: PoiPreviewActionMode.openOnly,
      preloadedPreview: PoiWikiPreview(
        qid: item.qid,
        title: item.name,
        summary: item.description,
        htmlContent: item.descriptionHtml,
        sourceUrl: item.wiki,
        languageCode: 'en',
      ),
    );
  }
}
