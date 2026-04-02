import 'package:flutter/material.dart';

class PremiumSurfaceGradients {
  PremiumSurfaceGradients._();

  static List<Color> pro({required bool isLightTheme}) {
    return isLightTheme
        ? const [Color(0xFFAA7003), Color(0xFFD59000), Color(0xFFE8B251)]
        : const [Color(0xFF4D3300), Color(0xFF936000), Color(0xFFB57D03)];
  }

  static List<Color> free({required bool isLightTheme}) {
    return isLightTheme
        ? const [Color(0xFF2A4A7E), Color(0xFF376DAA), Color(0xFF4C8DD0)]
        : const [Color(0xFF13213E), Color(0xFF1D3B69), Color(0xFF2A5E9C)];
  }
}

class PremiumDiagonalStripesOverlay extends StatelessWidget {
  const PremiumDiagonalStripesOverlay({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DiagonalStripesPainter(
        color: color ?? Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}

class PremiumAnimatedShimmerOverlay extends StatefulWidget {
  const PremiumAnimatedShimmerOverlay({super.key});

  @override
  State<PremiumAnimatedShimmerOverlay> createState() =>
      _PremiumAnimatedShimmerOverlayState();
}

class _PremiumAnimatedShimmerOverlayState
    extends State<PremiumAnimatedShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final center = -0.4 + (_controller.value * 1.8);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.11),
                Colors.white.withValues(alpha: 0.04),
                Colors.transparent,
              ],
              stops: [
                (center - 0.14).clamp(0.0, 1.0),
                (center - 0.05).clamp(0.0, 1.0),
                center.clamp(0.0, 1.0),
                (center + 0.05).clamp(0.0, 1.0),
                (center + 0.14).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiagonalStripesPainter extends CustomPainter {
  const _DiagonalStripesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const spacing = 14.0;
    for (double x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
