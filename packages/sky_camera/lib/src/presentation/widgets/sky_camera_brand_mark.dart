import 'package:flutter/material.dart';

class SkyCameraBrandMark extends StatelessWidget {
  const SkyCameraBrandMark({this.logoHeight = 28, super.key});

  static const brandAssetPath = 'assets/images/logo_new_with_text_white.png';

  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      brandAssetPath,
      key: const Key('sky_camera.brand_logo'),
      height: logoHeight,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        Icons.flight_rounded,
        size: logoHeight,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }
}
