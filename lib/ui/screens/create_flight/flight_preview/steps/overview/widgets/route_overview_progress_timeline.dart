import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/tokens/ds_brand_colors.dart';
import 'package:flymap/ui/theme/app_colours.dart';

class RouteOverviewProgressTimeline extends StatelessWidget {
  const RouteOverviewProgressTimeline({
    required this.itemCount,
    required this.selectedIndex,
    required this.isTitleActive,
    required this.isSummaryActive,
    this.enlargeSelectedDot = true,
    this.enlargePremiumRange = false,
    this.isPremiumRangeActive = false,
    this.premiumRangeStartIndex,
    this.premiumRangeEndIndex,
    super.key,
  });

  final int itemCount;
  final int selectedIndex;
  final bool isTitleActive;
  final bool isSummaryActive;
  final bool enlargeSelectedDot;
  final bool enlargePremiumRange;
  final bool isPremiumRangeActive;
  final int? premiumRangeStartIndex;
  final int? premiumRangeEndIndex;

  @override
  Widget build(BuildContext context) {
    final safeCount = itemCount < 2 ? 2 : itemCount;
    final safeSelected = selectedIndex.clamp(0, safeCount - 1);
    final timelineBlue = AppColoursCommon.brandBlue;
    final premiumGold = DsPremiumColors.accent(context);
    final currentGreen = AppColoursCommon.success;
    final futureColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final slot = width / safeCount;
          final firstCenter = slot * 0.5;
          final lastCenter = width - slot * 0.5;
          final currentCenter = firstCenter + slot * safeSelected;
          final titleMode = isTitleActive;
          final summaryMode = isSummaryActive;
          final showBlueLine = !titleMode;
          final hasPremiumRange =
              isPremiumRangeActive &&
              premiumRangeStartIndex != null &&
              premiumRangeEndIndex != null &&
              premiumRangeStartIndex! <= premiumRangeEndIndex! &&
              premiumRangeStartIndex! >= 0 &&
              premiumRangeEndIndex! < safeCount;
          final premiumStartCenter = hasPremiumRange
              ? firstCenter + slot * premiumRangeStartIndex!
              : 0.0;
          final premiumEndCenter = hasPremiumRange
              ? firstCenter + slot * premiumRangeEndIndex!
              : 0.0;
          final blueLineRight = summaryMode
              ? (width - lastCenter)
              : (width - currentCenter);

          return SizedBox(
            height: 26,
            child: Stack(
              children: [
                Positioned(
                  left: firstCenter,
                  right: width - lastCenter,
                  top: 12,
                  child: Container(height: 2, color: futureColor),
                ),
                if (showBlueLine)
                  if (hasPremiumRange) ...[
                    if (premiumRangeStartIndex! > 0)
                      Positioned(
                        left: firstCenter,
                        right: width - premiumStartCenter,
                        top: 12,
                        child: Container(height: 2, color: timelineBlue),
                      ),
                    Positioned(
                      left: premiumStartCenter,
                      right: width - premiumEndCenter,
                      top: 12,
                      child: Container(height: 2, color: premiumGold),
                    ),
                  ] else
                    Positioned(
                      left: firstCenter,
                      right: blueLineRight,
                      top: 12,
                      child: Container(height: 2, color: timelineBlue),
                    ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(safeCount, (index) {
                    final isCurrent = index == safeSelected;
                    final isCompleted = index < safeSelected;
                    final isInPremiumRange =
                        hasPremiumRange &&
                        index >= premiumRangeStartIndex! &&
                        index <= premiumRangeEndIndex!;
                    final color = titleMode
                        ? futureColor
                        : isInPremiumRange
                        ? premiumGold
                        : summaryMode
                        ? timelineBlue
                        : isCurrent
                        ? currentGreen
                        : isCompleted
                        ? timelineBlue
                        : futureColor;
                    final isPremiumEnlarged =
                        enlargePremiumRange && isInPremiumRange;
                    final dotSize =
                        (isCurrent && enlargeSelectedDot) || isPremiumEnlarged
                        ? 12.0
                        : 10.0;
                    final strokeWidth =
                        (isCurrent && enlargeSelectedDot) || isPremiumEnlarged
                        ? 2.4
                        : 2.0;
                    return Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color: color,
                              width: strokeWidth,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
