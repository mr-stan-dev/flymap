import 'dart:math' as math;
import 'dart:ui';

class SkyCameraMetricsPosition {
  const SkyCameraMetricsPosition({required this.x, required this.y});

  static const initial = SkyCameraMetricsPosition(x: 0.0, y: 0.5);

  final double x;
  final double y;

  Offset resolve({required Size containerSize, required Size childSize}) {
    final maxLeft = math.max(0.0, containerSize.width - childSize.width);
    final maxTop = math.max(0.0, containerSize.height - childSize.height);
    return Offset(x.clamp(0.0, 1.0) * maxLeft, y.clamp(0.0, 1.0) * maxTop);
  }

  SkyCameraMetricsPosition fromResolvedOffset({
    required Offset offset,
    required Size containerSize,
    required Size childSize,
  }) {
    final maxLeft = math.max(0.0, containerSize.width - childSize.width);
    final maxTop = math.max(0.0, containerSize.height - childSize.height);
    final clampedLeft = offset.dx.clamp(0.0, maxLeft);
    final clampedTop = offset.dy.clamp(0.0, maxTop);
    return SkyCameraMetricsPosition(
      x: maxLeft <= 0 ? 0.0 : clampedLeft / maxLeft,
      y: maxTop <= 0 ? 0.0 : clampedTop / maxTop,
    );
  }
}
