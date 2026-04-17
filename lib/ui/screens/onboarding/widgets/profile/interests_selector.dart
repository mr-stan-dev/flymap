import 'package:flutter/material.dart';
import 'package:flymap/entity/onboarding_profile.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/onboarding/model/onboarding_profile_ui.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_state.dart';

class InterestsSelector extends StatelessWidget {
  const InterestsSelector({
    required this.selectedInterests,
    required this.onToggleInterest,
    super.key,
  });

  final List<OnboardingInterest> selectedInterests;
  final ValueChanged<OnboardingInterest> onToggleInterest;

  @override
  Widget build(BuildContext context) {
    final hasReachedLimit =
        selectedInterests.length >= OnboardingProfileFormState.maxInterests;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          children: OnboardingInterest.values.map((interest) {
            final isSelected = selectedInterests.contains(interest);
            final canSelect = isSelected || !hasReachedLimit;
            return FilterChip(
              label: Text(
                interest.label(context),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              avatar: Icon(
                interest.icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.24),
              ),
              backgroundColor: colorScheme.surfaceContainerHighest,
              selectedColor: colorScheme.primary,
              showCheckmark: false,
              onSelected: canSelect ? (_) => onToggleInterest(interest) : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          selectedInterests.isEmpty
              ? context.t.onboarding.interestsHelper
              : context.t.onboarding.interestsSelected(
                  count: selectedInterests.length,
                  max: OnboardingProfileFormState.maxInterests,
                ),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
