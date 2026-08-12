import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/domain/policy/share_flight_card_policy.dart';
import 'package:flymap/ui/screens/shared/region_artwork.dart';

class ShareRouteCardRegionChip extends StatelessWidget {
  const ShareRouteCardRegionChip({
    required this.chip,
    required this.textStyle,
    super.key,
  });

  final ShareFlightCardChip chip;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final code = chip.countryCode?.trim().toUpperCase() ?? '';
    final regionType = chip.regionType;
    final showRegionIcon = _shouldShowRegionIcon(regionType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xB42A3749),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x6C91A3B8), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chip.isAirport) ...[
            if (code.length == 2)
              Opacity(
                opacity: 0.7,
                child: CountryFlag.fromCountryCode(
                  code,
                  width: 12,
                  height: 12,
                  shape: const Circle(),
                ),
              )
            else
              const Icon(Icons.circle, color: Color(0xFFBEEFFF), size: 10),
            const SizedBox(width: 4),
          ] else if ((regionType == RouteRegionType.country) &&
              code.length == 2) ...[
            Opacity(
              opacity: 0.7,
              child: CountryFlag.fromCountryCode(
                code,
                width: 12,
                height: 12,
                shape: const Circle(),
              ),
            ),
            const SizedBox(width: 4),
          ] else if (showRegionIcon) ...[
            RegionArtwork(
              regionName: chip.label,
              regionType: regionType ?? RouteRegionType.region,
              size: 12,
              isCircle: true,
            ),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 104),
            child: Text(
              chip.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowRegionIcon(RouteRegionType? type) {
    if (type == null) return false;
    if (type == RouteRegionType.country) return true;
    return type.assetImagePath != null;
  }
}
