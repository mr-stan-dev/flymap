import 'package:flutter/material.dart';

class ZoomIndicator extends StatelessWidget {
  const ZoomIndicator({required this.topOffset, required this.zoom, super.key});

  final double topOffset;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final zoomLabel = zoom.toStringAsFixed(1);

    return Positioned(
      left: 8,
      top: topOffset,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Zoom $zoomLabel',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
