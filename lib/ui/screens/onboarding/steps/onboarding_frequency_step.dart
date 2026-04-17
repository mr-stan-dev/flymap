import 'package:flutter/material.dart';
import 'package:flymap/entity/onboarding_profile.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:flymap/ui/screens/onboarding/widgets/profile/flying_frequency_selector.dart';

class OnboardingFrequencyStep extends StatelessWidget {
  const OnboardingFrequencyStep({
    required this.title,
    required this.subtitle,
    required this.selectedFrequency,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String subtitle;
  final FlyingFrequency? selectedFrequency;
  final ValueChanged<FlyingFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: title,
      subtitle: subtitle,
      body: FlyingFrequencySelector(
        selectedFrequency: selectedFrequency,
        onChanged: onChanged,
      ),
    );
  }
}
