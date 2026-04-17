import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_window_image.dart';

class OnboardingProStep extends StatelessWidget {
  const OnboardingProStep({
    required this.title,
    required this.isPro,
    required this.onTryPro,
    super.key,
  });

  final String title;
  final bool isPro;
  final Future<void> Function() onTryPro;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: title,
      subtitle: context.t.onboarding.proStepSubtitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const OnboardingWindowImage(
                assetPath: 'assets/images/onboarding2.webp',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isPro)
            _ActiveProBadge()
          else
            PremiumButton(
              label: context.t.onboarding.unlockPro,
              onPressed: onTryPro,
              trailingIcon: Icons.arrow_forward_rounded,
            ),
          if (!isPro) ...[
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _ActiveProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'PRO',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
