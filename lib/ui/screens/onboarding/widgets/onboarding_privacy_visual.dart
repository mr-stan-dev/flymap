import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPrivacyVisual extends StatelessWidget {
  const OnboardingPrivacyVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 260,
      height: 316,
      child: Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Image.asset(
                    'assets/app_icon.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              Positioned(
                right: -24,
                bottom: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/images/icons/shield-check.svg',
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      Colors.green.shade600,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.scrim.withValues(alpha: 0.0),
                          colorScheme.scrim.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    child: const SizedBox(height: 56),
                  ),
                ),
              ),
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.16),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
