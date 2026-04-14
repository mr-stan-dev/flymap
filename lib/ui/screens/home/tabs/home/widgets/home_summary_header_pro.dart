import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/tokens/ds_brand_colors.dart';
import 'package:flymap/ui/design_system/tokens/ds_radii.dart';
import 'package:flymap/ui/design_system/tokens/ds_spacing.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';

class HomeSummaryHeaderPro extends StatelessWidget {
  const HomeSummaryHeaderPro({required this.statistics, super.key});

  final FlightStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(DsRadii.xl);
    final gradientColors = [
      colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      DsBrandColors.proAmber.withValues(
        alpha: theme.brightness == Brightness.light ? 0.16 : 0.22,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: DsBrandColors.proAmber.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DsBrandColors.proAmber.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: DsBrandColors.proAmber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(
                    context.t.home.welcomeTitlePro,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.sm),
            Text(
              context.t.home.welcomeSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            Wrap(
              spacing: DsSpacing.sm,
              runSpacing: DsSpacing.sm,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DsBrandColors.proAmber),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
