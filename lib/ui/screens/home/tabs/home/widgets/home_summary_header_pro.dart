import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/tokens/ds_brand_colors.dart';
import 'package:flymap/ui/design_system/tokens/ds_radii.dart';
import 'package:flymap/ui/design_system/tokens/ds_spacing.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';

class HomeSummaryHeaderPro extends StatelessWidget {
  const HomeSummaryHeaderPro({
    required this.statistics,
    required this.displayName,
    required this.hasInternet,
    required this.hasInProgressFlights,
    super.key,
  });

  final FlightStatistics statistics;
  final String displayName;
  final bool hasInternet;
  final bool hasInProgressFlights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(DsRadii.xl);
    final gradientColors = DsPremiumColors.activeCardGradient(context);
    final iconBorderColor = DsPremiumColors.activeCardIconBorder(context);

    return Container(
      key: const Key('home-pro-summary-surface'),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(color: DsPremiumColors.border(context)),
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
                    color: DsPremiumColors.activeCardIconSurface(context),
                    shape: BoxShape.circle,
                    border: iconBorderColor == null
                        ? null
                        : Border.all(color: iconBorderColor),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: DsPremiumColors.accent(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(
                    _resolveWelcomeTitle(context),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.md),
            Wrap(
              spacing: DsSpacing.sm,
              runSpacing: DsSpacing.sm,
              children: [
                _ProSummaryPill(
                  icon: Icons.flight,
                  label: context.t.home.totalFlights,
                  value: '${statistics.totalFlights}',
                ),
                _ProSummaryPill(
                  icon: Icons.route,
                  label: context.t.home.totalDistance,
                  value: statistics.formattedTotalDistance,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _resolveWelcomeTitle(BuildContext context) {
    final trimmedName = displayName.trim();
    if (hasInProgressFlights) {
      return trimmedName.isNotEmpty
          ? context.t.home.greetingInProgressWithName(name: trimmedName)
          : context.t.home.greetingInProgress;
    }
    if (trimmedName.isNotEmpty) {
      return hasInternet
          ? context.t.home.greetingOnlineWithName(name: trimmedName)
          : context.t.home.greetingOfflineWithName(name: trimmedName);
    }
    return hasInternet
        ? context.t.home.greetingOnline
        : context.t.home.greetingOffline;
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
        color: DsPremiumColors.activeCardPillSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DsPremiumColors.activeCardPillBorder(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DsPremiumColors.accent(context)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color:
                  DsPremiumColors.activeCardPillForeground(context) ??
                  colorScheme.onSurface.withValues(alpha: 0.72),
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
