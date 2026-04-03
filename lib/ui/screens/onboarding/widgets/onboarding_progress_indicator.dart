import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    required this.count,
    required this.activeIndex,
    super.key,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: DsMotion.fast,
          curve: DsMotion.fastInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
