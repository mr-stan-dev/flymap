import 'package:flutter/material.dart';

class WikipediaLogoAvatar extends StatelessWidget {
  const WikipediaLogoAvatar({this.size = 36, super.key});

  static const _wikipediaLogoIconAsset =
      'assets/images/wikipedia_logo_icon.webp';

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        _wikipediaLogoIconAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Center(
            child: Text(
              'W',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }
}
