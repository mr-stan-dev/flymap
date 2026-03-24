import 'dart:math' as math;

import 'package:flutter/material.dart';

class CompassRosePainter extends CustomPainter {
  CompassRosePainter({required this.color, required this.accentColor});

  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const tickLength = 10.0;
    const majorTickLength = 15.0;

    final minorPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final majorPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 360; i += 5) {
      final isMajor = i % 90 == 0;
      final isSemiMajor = i % 30 == 0;
      final angle = (i - 90) * (math.pi / 180);
      final currentTickLength = isMajor
          ? majorTickLength + 5
          : isSemiMajor
          ? majorTickLength
          : tickLength;

      final p1 = Offset(
        center.dx + (radius - currentTickLength - 10) * math.cos(angle),
        center.dy + (radius - currentTickLength - 10) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );

      canvas.drawLine(p1, p2, isMajor || isSemiMajor ? majorPaint : minorPaint);
      if (!isMajor) {
        continue;
      }

      String label = '';
      switch (i) {
        case 0:
          label = 'N';
        case 90:
          label = 'E';
        case 180:
          label = 'S';
        case 270:
          label = 'W';
      }

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: i == 0 ? accentColor : color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final textRadius = radius - 45;
      final textOffset = Offset(
        center.dx + textRadius * math.cos(angle) - textPainter.width / 2,
        center.dy + textRadius * math.sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
