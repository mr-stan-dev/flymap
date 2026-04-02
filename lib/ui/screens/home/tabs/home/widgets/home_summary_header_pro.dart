import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/tokens/ds_brand_colors.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:flymap/ui/widgets/premium_surface_effects.dart';

class HomeSummaryHeaderPro extends StatelessWidget {
  const HomeSummaryHeaderPro({required this.statistics, super.key});

  final FlightStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;
    final radius = BorderRadius.circular(20);
    final gradientColors = PremiumSurfaceGradients.pro(
      isLightTheme: isLightTheme,
    );

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  border: Border.all(
                    color: DsBrandColors.proAmber.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: PremiumDiagonalStripesOverlay()),
            Positioned(
              right: -18,
              top: -26,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white.withValues(alpha: 0.1),
                size: 124,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(child: PremiumAnimatedShimmerOverlay()),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.home.welcomeTitlePro,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t.home.welcomeSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ProSummaryPill(
                        icon: Icons.flight,
                        label: context.t.home.flightsSaved,
                        value: '${statistics.totalFlights}',
                      ),
                      _ProSummaryPill(
                        icon: Icons.map,
                        label: context.t.home.storageUsed,
                        value: statistics.formattedTotalMapSize,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProSummaryPill extends StatelessWidget {
  const _ProSummaryPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
