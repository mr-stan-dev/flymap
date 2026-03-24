import 'package:flutter/material.dart';

class FlightMapControls extends StatefulWidget {
  const FlightMapControls({
    required this.topOffset,
    required this.visible,
    required this.is3D,
    required this.followUser,
    required this.onToggle3D,
    required this.onToggleFollowUser,
    super.key,
  });

  final double topOffset;
  final bool visible;
  final bool is3D;
  final bool followUser;
  final Future<void> Function() onToggle3D;
  final VoidCallback onToggleFollowUser;

  @override
  State<FlightMapControls> createState() => _FlightMapControlsState();
}

class _FlightMapControlsState extends State<FlightMapControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _syncPulse(widget.followUser);
  }

  @override
  void didUpdateWidget(covariant FlightMapControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.followUser != widget.followUser) {
      _syncPulse(widget.followUser);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _syncPulse(bool active) {
    if (active) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topOffset,
      right: 8,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: widget.visible ? 1 : 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'flight_map_3d_fab',
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                mini: true,
                onPressed: () {
                  widget.onToggle3D();
                },
                child: Icon(
                  widget.is3D
                      ? Icons.threed_rotation
                      : Icons.threed_rotation_outlined,
                ),
              ),
              const SizedBox(height: 8),
              ScaleTransition(
                scale: _pulseAnimation,
                child: FloatingActionButton(
                  heroTag: 'flight_map_follow_fab',
                  backgroundColor: widget.followUser
                      ? Colors.green.withValues(alpha: 0.75)
                      : Colors.black.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  mini: true,
                  onPressed: widget.onToggleFollowUser,
                  child: Icon(
                    widget.followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
