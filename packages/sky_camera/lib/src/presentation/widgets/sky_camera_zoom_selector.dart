import 'package:flutter/material.dart';

class SkyCameraZoomSelector extends StatelessWidget {
  const SkyCameraZoomSelector({
    required this.zoomLevels,
    required this.currentZoomLevel,
    required this.onSelected,
    super.key,
  });

  final List<double> zoomLevels;
  final double currentZoomLevel;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    if (zoomLevels.length < 2) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final zoomLevel in zoomLevels)
              _ZoomOption(
                zoomLevel: zoomLevel,
                isSelected: (zoomLevel - currentZoomLevel).abs() < 0.15,
                onTap: () => onSelected(zoomLevel),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomOption extends StatelessWidget {
  const _ZoomOption({
    required this.zoomLevel,
    required this.isSelected,
    required this.onTap,
  });

  final double zoomLevel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '${zoomLevel.round()}x';
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        key: Key('sky_camera.zoom_${zoomLevel.round()}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? Colors.black.withValues(alpha: 0.72)
                : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFFD400) : Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
