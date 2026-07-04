import 'package:flutter/material.dart';
import 'package:sky_camera/src/presentation/sky_camera_strings.dart';

class SkyCameraLoadingOverlay extends StatelessWidget {
  const SkyCameraLoadingOverlay({required this.strings, super.key});

  final SkyCameraStrings strings;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xD006090F),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              strings.loadingCamera,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
