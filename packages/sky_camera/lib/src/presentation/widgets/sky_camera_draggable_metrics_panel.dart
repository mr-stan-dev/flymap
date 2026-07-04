import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sky_camera/src/presentation/sky_camera_metrics_position.dart';

class SkyCameraDraggableMetricsPanel extends StatefulWidget {
  const SkyCameraDraggableMetricsPanel({
    required this.position,
    required this.onChanged,
    required this.child,
    super.key,
  });

  final SkyCameraMetricsPosition position;
  final ValueChanged<SkyCameraMetricsPosition> onChanged;
  final Widget child;

  @override
  State<SkyCameraDraggableMetricsPanel> createState() =>
      _SkyCameraDraggableMetricsPanelState();
}

class _SkyCameraDraggableMetricsPanelState
    extends State<SkyCameraDraggableMetricsPanel> {
  final GlobalKey _childKey = GlobalKey();
  Size _childSize = Size.zero;
  bool _isDragging = false;
  Offset? _dragStartOffset;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChild());
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        final offset = widget.position.resolve(
          containerSize: containerSize,
          childSize: _childSize,
        );
        return Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: GestureDetector(
                key: const Key('sky_camera.metrics_panel_drag_area'),
                behavior: HitTestBehavior.opaque,
                onLongPressStart: (_) {
                  _dragStartOffset = offset;
                  setState(() => _isDragging = true);
                  HapticFeedback.mediumImpact();
                },
                onLongPressMoveUpdate: (details) {
                  if (!_isDragging) return;
                  final dragStartOffset = _dragStartOffset ?? offset;
                  final nextPosition = widget.position.fromResolvedOffset(
                    offset: dragStartOffset + details.offsetFromOrigin,
                    containerSize: containerSize,
                    childSize: _childSize,
                  );
                  widget.onChanged(nextPosition);
                },
                onLongPressEnd: (_) {
                  _dragStartOffset = null;
                  if (!mounted) return;
                  setState(() => _isDragging = false);
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  scale: _isDragging ? 1.03 : 1,
                  child: KeyedSubtree(key: _childKey, child: widget.child),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _measureChild() {
    final size = _childKey.currentContext?.size;
    if (size == null || size == _childSize || !mounted) return;
    setState(() => _childSize = size);
  }
}
