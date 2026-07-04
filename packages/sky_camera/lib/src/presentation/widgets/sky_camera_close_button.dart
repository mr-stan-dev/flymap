import 'package:flutter/material.dart';

class SkyCameraCloseButton extends StatelessWidget {
  const SkyCameraCloseButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 12),
          child: Semantics(
            button: true,
            label: label,
            child: Material(
              color: const Color(0xAA161A20),
              shape: const CircleBorder(),
              child: IconButton(
                key: const Key('sky_camera.close_button'),
                onPressed: onPressed,
                tooltip: label,
                iconSize: 22,
                padding: const EdgeInsets.all(12),
                visualDensity: VisualDensity.compact,
                splashRadius: 22,
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
