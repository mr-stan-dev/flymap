import 'package:flutter/material.dart';

class SkyCameraFocusRing extends StatefulWidget {
  const SkyCameraFocusRing({
    required this.focusPoint,
    required this.onFinished,
    super.key,
  });

  final Offset focusPoint;
  final VoidCallback onFinished;

  @override
  State<SkyCameraFocusRing> createState() => _SkyCameraFocusRingState();
}

class _SkyCameraFocusRingState extends State<SkyCameraFocusRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward().whenComplete(widget.onFinished);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.focusPoint.dx - 28,
      top: widget.focusPoint.dy - 28,
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 1,
          end: 0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.08).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          ),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
