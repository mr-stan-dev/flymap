import 'package:flutter/material.dart';

class ShareFlymapWatermark extends StatelessWidget {
  const ShareFlymapWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
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
                ..strokeWidth = 1.3
                ..color = Colors.white.withValues(alpha: 0.34),
            ),
          ),
          Text(
            'Flymap',
            style: textStyle?.copyWith(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
