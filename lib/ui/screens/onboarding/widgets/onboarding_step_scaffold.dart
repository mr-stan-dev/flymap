import 'package:flutter/material.dart';

class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.centerHeader = false,
    this.bodyPadding = const EdgeInsets.fromLTRB(20, 0, 20, 12),
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool centerHeader;
  final Widget body;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: centerHeader
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: centerHeader
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                title,
                textAlign: centerHeader ? TextAlign.center : null,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  textAlign: centerHeader ? TextAlign.center : null,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(padding: bodyPadding, child: body),
        ),
      ],
    );
  }
}
