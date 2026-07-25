import 'package:flutter/material.dart';

/// Airplane-window-shaped frame used by the onboarding welcome step.
/// Renders [content] clipped to the window shape, with the glass gradient
/// and rim border on top.
class OnboardingWindow extends StatelessWidget {
  const OnboardingWindow({required this.content, super.key});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 260,
      height: 316,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhysicalShape(
            clipper: const _AirplaneWindowClipper(),
            color: colorScheme.surfaceContainerHighest,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.34),
            elevation: 10,
            child: const SizedBox.expand(),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ClipPath(
              clipper: const _AirplaneWindowClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  content,
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.04),
                          colorScheme.scrim.withValues(alpha: 0.16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: IgnorePointer(
              child: ClipPath(
                clipper: const _AirplaneWindowClipper(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingWindowImage extends StatelessWidget {
  const OnboardingWindowImage({required this.assetPath, super.key});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return OnboardingWindow(content: Image.asset(assetPath, fit: BoxFit.cover));
  }
}

class _AirplaneWindowClipper extends CustomClipper<Path> {
  const _AirplaneWindowClipper();

  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(size.width * 0.34, 0);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.02,
      size.width * 0.66,
      0,
    );

    path.quadraticBezierTo(
      size.width * 0.89,
      size.height * 0.09,
      size.width * 0.89,
      size.height * 0.32,
    );
    path.lineTo(size.width * 0.89, size.height * 0.68);
    path.quadraticBezierTo(
      size.width * 0.89,
      size.height * 0.91,
      size.width * 0.66,
      size.height,
    );

    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.02,
      size.width * 0.34,
      size.height,
    );
    path.quadraticBezierTo(
      size.width * 0.11,
      size.height * 0.91,
      size.width * 0.11,
      size.height * 0.68,
    );
    path.lineTo(size.width * 0.11, size.height * 0.32);
    path.quadraticBezierTo(
      size.width * 0.11,
      size.height * 0.09,
      size.width * 0.34,
      0,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
