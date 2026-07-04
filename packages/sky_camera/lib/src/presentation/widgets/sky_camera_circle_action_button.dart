import 'package:flutter/material.dart';

class SkyCameraCircleActionButton extends StatelessWidget {
  const SkyCameraCircleActionButton({
    required this.buttonKey,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
  });

  final Key buttonKey;
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x96121824),
      shape: const CircleBorder(),
      child: IconButton(
        key: buttonKey,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
