import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/shared/region_artwork.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_region_type_mapper.dart';

class RouteRegionsByTypeSection extends StatelessWidget {
  const RouteRegionsByTypeSection({
    super.key,
    required this.regions,
    this.hiddenRegions = const [],
    this.onOpenRegion,
    this.onPremiumGateTap,
  });

  final List<RouteRegion> regions;

  /// Premium-gated regions: shown as locked teaser chips (type only, names
  /// stay hidden) so free users see the shape of what Pro unlocks.
  final List<RouteRegion> hiddenRegions;
  final ValueChanged<RouteRegion>? onOpenRegion;
  final VoidCallback? onPremiumGateTap;

  static const _typeMapper = RouteTimelineRegionTypeMapper();

  @override
  Widget build(BuildContext context) {
    final groups = _groupRegionsByType(regions);
    final totalRegionsCount = regions.length + hiddenRegions.length;
    if (groups.isEmpty && hiddenRegions.isEmpty) {
      return const SizedBox.shrink();
    }

    final t = context.t;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatRegionsTitle(context, totalRegionsCount),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < groups.length; i++) ...[
            _RegionTypeSection(
              regions: groups[i].regions,
              onOpenRegion: onOpenRegion,
            ),
            if (i != groups.length - 1 || hiddenRegions.isNotEmpty)
              const SizedBox(height: 10),
          ],
          if (hiddenRegions.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final region in hiddenRegions)
                  SelectionChip(
                    label: _typeMapper.mapLabel(context, region.regionType),
                    leading: Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onPremiumGateTap,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              // "Unlock all N regions" — N is the route total, matching the
              // section title, not just the locked remainder.
              t.createFlight.overview.premiumGateBodyWithCount(
                count: totalRegionsCount,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onPremiumGateTap != null) ...[
              const SizedBox(height: 10),
              PremiumButton(
                label: t.createFlight.overview.premiumGateCta,
                onPressed: onPremiumGateTap,
                trailingIcon: Icons.arrow_forward_rounded,
                expand: false,
              ),
            ],
          ],
        ],
      ),
    );
  }

  List<_RouteRegionTypeGroup> _groupRegionsByType(List<RouteRegion> regions) {
    final sorted = List<RouteRegion>.of(regions)
      ..sort((a, b) {
        final byType = _typeRank(
          a.regionType,
        ).compareTo(_typeRank(b.regionType));
        if (byType != 0) return byType;

        final byPath = a.pathFirstEncounterKm.compareTo(b.pathFirstEncounterKm);
        if (byPath != 0) return byPath;

        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (byName != 0) return byName;
        return a.qid.compareTo(b.qid);
      });

    final seenIds = <String>{};
    final grouped = <RouteRegionType, List<RouteRegion>>{};
    for (final region in sorted) {
      if (region.name.trim().isEmpty || !seenIds.add(region.qid)) continue;
      grouped.putIfAbsent(region.regionType, () => <RouteRegion>[]).add(region);
    }

    final groups = grouped.entries
        .map(
          (entry) =>
              _RouteRegionTypeGroup(type: entry.key, regions: entry.value),
        )
        .toList(growable: false);
    groups.sort((a, b) {
      final byCount = b.regions.length.compareTo(a.regions.length);
      if (byCount != 0) return byCount;
      return _typeRank(a.type).compareTo(_typeRank(b.type));
    });
    return groups;
  }

  String _formatRegionsTitle(BuildContext context, int count) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final singular = _typeMapper.mapLabel(context, RouteRegionType.region);
    final plural = context.t.createFlight.overview.routeSummaryRegionsLabel;
    final regionWord = count == 1 ? singular : plural;
    final normalizedRegionWord = switch (localeCode) {
      'de' => regionWord,
      _ => _lowercaseFirst(regionWord),
    };
    return '${context.t.createFlight.overview.routeSummaryRegionsTitle} $count $normalizedRegionWord';
  }

  String _lowercaseFirst(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toLowerCase()}${value.substring(1)}';
  }

  int _typeRank(RouteRegionType type) {
    switch (type) {
      case RouteRegionType.country:
        return 0;
      case RouteRegionType.region:
        return 1;
      case RouteRegionType.state:
        return 2;
      case RouteRegionType.province:
        return 3;
      case RouteRegionType.continent:
      case RouteRegionType.geoarea:
        return 4;
      case RouteRegionType.strait:
      case RouteRegionType.channel:
      case RouteRegionType.sea:
      case RouteRegionType.ocean:
        return 20;
      case RouteRegionType.gulf:
        return 21;
      case RouteRegionType.bay:
        return 22;
      case RouteRegionType.alkalineLake:
      case RouteRegionType.lake:
        return 25;
      case RouteRegionType.archipelago:
      case RouteRegionType.island:
        return 30;
      case RouteRegionType.peninsula:
      case RouteRegionType.coast:
        return 32;
      case RouteRegionType.reservoir:
      case RouteRegionType.delta:
        return 33;
      case RouteRegionType.mountainRange:
      case RouteRegionType.valley:
      case RouteRegionType.plateau:
      case RouteRegionType.plain:
      case RouteRegionType.basin:
      case RouteRegionType.lowland:
      case RouteRegionType.tundra:
      case RouteRegionType.wetlands:
      case RouteRegionType.desert:
        return 40;
      case RouteRegionType.isthmus:
      case RouteRegionType.unknown:
        return 50;
    }
  }
}

class _RouteRegionTypeGroup {
  const _RouteRegionTypeGroup({required this.type, required this.regions});

  final RouteRegionType type;
  final List<RouteRegion> regions;
}

class _RegionTypeSection extends StatelessWidget {
  const _RegionTypeSection({required this.regions, required this.onOpenRegion});

  final List<RouteRegion> regions;
  final ValueChanged<RouteRegion>? onOpenRegion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                RouteRegionsByTypeSection._typeMapper.mapCountLabel(
                  context,
                  regions.first.regionType,
                  regions.length,
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: regions
              .map(
                (region) => SelectionChip(
                  label: region.name,
                  onPressed: onOpenRegion == null
                      ? null
                      : () => onOpenRegion!(region),
                  leading: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.transparent,
                    child: RegionArtwork(
                      regionName: region.name,
                      regionType: region.regionType,
                      size: 18,
                      isCircle: true,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
