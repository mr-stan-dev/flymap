import 'package:flutter/material.dart';

class ShareFlymapWatermark extends StatelessWidget {
  const ShareFlymapWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );
    return IgnorePointer(
      child: Stack(
        children: [
          Text(
            'Flymap',
            style: textStyle?.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2
                ..color = colorScheme.onSurface.withValues(alpha: 0.34),
            ),
          ),
          Text(
            'Flymap',
            style: textStyle?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
