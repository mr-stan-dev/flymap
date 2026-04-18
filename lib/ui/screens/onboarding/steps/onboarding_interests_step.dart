import 'package:flutter/material.dart';
import 'package:flymap/entity/user_profile.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:flymap/ui/screens/onboarding/widgets/profile/interests_selector.dart';

class OnboardingInterestsStep extends StatelessWidget {
  const OnboardingInterestsStep({
    required this.title,
    required this.subtitle,
    required this.selectedInterests,
    required this.onToggleInterest,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<UsersInterests> selectedInterests;
  final ValueChanged<UsersInterests> onToggleInterest;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: title,
      subtitle: subtitle,
      body: InterestsSelector(
        selectedInterests: selectedInterests,
        onToggleInterest: onToggleInterest,
      ),
    );
  }
}
