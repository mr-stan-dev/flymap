import 'package:flutter/material.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/map_download_config.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/map_preview/flight_map_preview_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/map_preview/map_detail_hint.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/map_preview/map_detail_level_button.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/usecase/poi_selection_config.dart';

class FlightSearchMapPreviewStep extends StatelessWidget {
  const FlightSearchMapPreviewStep({
    required this.state,
    required this.isProUser,
    required this.onContinue,
    required this.onSelectMapDetailLevel,
    super.key,
  });

  final FlightPreviewState state;
  final bool isProUser;
  final VoidCallback onContinue;
  final ValueChanged<MapDetailLevel> onSelectMapDetailLevel;

  @override
  Widget build(BuildContext context) {
    final route = state.flightRoute;
    if (state.isPreviewLoading || route == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final selectedDetailLevel = isProUser
        ? MapDetailLevel.pro
        : state.selectedMapDetailLevel;
    if (isProUser && state.selectedMapDetailLevel != MapDetailLevel.pro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSelectMapDetailLevel(MapDetailLevel.pro);
      });
    }
    final isFreeUserWithProSelection =
        !isProUser && selectedDetailLevel == MapDetailLevel.pro;
    final poiCount = state.flightInfo.poi.length;
    final proPoiCount =
        state.proPoiCount ??
        (selectedDetailLevel == MapDetailLevel.pro
            ? poiCount
            : PoiSelectionConfig.proMaxPois);
    final resolvedMaxZoom = MapDownloadConfig.resolveMaxZoom(
      distanceKm: route.distanceInKm,
      detailLevel: selectedDetailLevel,
    ).toDouble();
    final estimatedMapSize = MapUtils.estimatedDownloadSizeRangeLabel(
      route: route,
      mapDetailLevel: selectedDetailLevel,
      selectedArticlesCount: 0,
    );

    return Column(
      children: [
        Expanded(
          child: FlightMapPreviewWidget(
            flightRoute: route,
            flightInfo: state.flightInfo,
            minZoom: MapDownloadConfig.minDownloadZoom.toDouble(),
            maxZoom: resolvedMaxZoom,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isProUser) ...[
                Row(
                  children: [
                    Expanded(
                      child: MapDetailLevelButton(
                        label: context.t.createFlight.mapPreview.basic,
                        icon: Icons.map_outlined,
                        selected: selectedDetailLevel == MapDetailLevel.basic,
                        onPressed: () =>
                            onSelectMapDetailLevel(MapDetailLevel.basic),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MapDetailLevelButton(
                        label: context.t.createFlight.mapPreview.pro,
                        icon: Icons.workspace_premium_rounded,
                        selected: selectedDetailLevel == MapDetailLevel.pro,
                        selectedBorderColor: DsBrandColors.proAmber,
                        onPressed: () =>
                            onSelectMapDetailLevel(MapDetailLevel.pro),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              MapDetailHint(
                message: switch ((isProUser, isFreeUserWithProSelection)) {
                  (true, _) => context.t.createFlight.mapPreview.proHint(
                    count: poiCount,
                  ),
                  (false, true) =>
                    context.t.createFlight.mapPreview.proGateHint(
                      count: proPoiCount,
                    ),
                  _ => context.t.createFlight.mapPreview.basicHint(
                    count: poiCount,
                  ),
                },
                details: context.t.createFlight.mapPreview.estimatedMapSize(
                  size: estimatedMapSize,
                ),
                highlighted: isFreeUserWithProSelection,
              ),
              const SizedBox(height: 12),
              isFreeUserWithProSelection
                  ? PremiumButton(
                      onPressed: state.canContinueFromMap ? onContinue : null,
                      label: context.t.createFlight.mapPreview.upgradeToPro,
                      icon: Icons.workspace_premium_rounded,
                    )
                  : PrimaryButton(
                      onPressed: state.canContinueFromMap ? onContinue : null,
                      label: context.t.common.kContinue,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
