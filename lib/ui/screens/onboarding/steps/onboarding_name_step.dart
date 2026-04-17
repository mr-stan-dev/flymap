import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:flymap/ui/screens/onboarding/widgets/profile/profile_name_field.dart';

class OnboardingNameStep extends StatelessWidget {
  const OnboardingNameStep({
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String subtitle;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: title,
      subtitle: subtitle,
      body: ProfileNameField(initialValue: initialValue, onChanged: onChanged),
    );
  }
}
