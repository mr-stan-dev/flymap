import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';

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
            t.shareFlight.watermark,
            style: textStyle?.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2
                ..color = colorScheme.onSurface.withValues(alpha: 0.34),
            ),
          ),
          Text(
            t.shareFlight.watermark,
            style: textStyle?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
