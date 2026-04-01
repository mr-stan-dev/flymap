import 'package:flutter/material.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/map_download_config.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/map/flight_map_preview_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/map/map_utils.dart';

class FlightSearchMapPreviewStep extends StatelessWidget {
  const FlightSearchMapPreviewStep({
    required this.state,
    required this.isProUser,
    required this.onContinue,
    required this.onSelectMapDetailLevel,
    super.key,
  });

  final FlightSearchScreenState state;
  final bool isProUser;
  final VoidCallback onContinue;
  final ValueChanged<MapDetailLevel> onSelectMapDetailLevel;

  @override
  Widget build(BuildContext context) {
    final route = state.flightRoute;
    if (state.isPreviewLoading || route == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final selectedDetailLevel = state.selectedMapDetailLevel;
    final isFreeUserWithProSelection =
        !isProUser && selectedDetailLevel == MapDetailLevel.pro;
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
        if (state.isTooLongFlight)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Downloading routes over 5,000 km is not supported yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MapDetailLevelButton(
                      label: 'Basic',
                      icon: Icons.map_outlined,
                      selected: selectedDetailLevel == MapDetailLevel.basic,
                      onPressed: () =>
                          onSelectMapDetailLevel(MapDetailLevel.basic),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MapDetailLevelButton(
                      label: 'Pro',
                      icon: Icons.workspace_premium_rounded,
                      selected: selectedDetailLevel == MapDetailLevel.pro,
                      selectedBorderColor: DsBrandColors.proAmber,
                      onPressed: () =>
                          onSelectMapDetailLevel(MapDetailLevel.pro),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _showMapDetailLevelInfoDialog(context),
                    tooltip: 'Map detail info',
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              if (!state.isTooLongFlight) ...[
                const SizedBox(height: 10),
                Text(
                  'Estimated map download size: $estimatedMapSize',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              isFreeUserWithProSelection
                  ? PremiumButton(
                      onPressed: state.canContinueFromMap ? onContinue : null,
                      label: 'Upgrade to Pro',
                      icon: Icons.workspace_premium_rounded,
                    )
                  : PrimaryButton(
                      onPressed: state.canContinueFromMap ? onContinue : null,
                      label: 'Continue',
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showMapDetailLevelInfoDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Map options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic map has lower zoom but download is faster and uses less storage. \n \nPro gives you a higher zoom, more details but download size is bigger.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _MapDetailLevelButton extends StatelessWidget {
  const _MapDetailLevelButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.selectedBorderColor,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final Color? selectedBorderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor =
        selectedBorderColor ?? Theme.of(context).colorScheme.primary;
    final effectiveBorderColor = selected
        ? borderColor
        : colorScheme.outline.withValues(alpha: 0.35);
    final contentColor = selected ? borderColor : colorScheme.onSurface;

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: effectiveBorderColor, width: 1.5),
        ),
        onPressed: onPressed,
        child: _MapDetailLevelButtonContent(
          label: label,
          icon: icon,
          color: contentColor,
        ),
      ),
    );
  }
}

class _MapDetailLevelButtonContent extends StatelessWidget {
  const _MapDetailLevelButtonContent({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
