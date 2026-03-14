import 'dart:math';

import 'package:flutter/material.dart';

/// A small circular icon that paints the current moon phase geometrically,
/// using the same shadow algorithm as [MoonPainter] but without an image.
class MoonPhaseIcon extends StatelessWidget {
  final double phase;
  final double size;

  const MoonPhaseIcon({super.key, required this.phase, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoonPhaseIconPainter(
          phase: phase,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _MoonPhaseIconPainter extends CustomPainter {
  final double phase;
  final Color color;

  const _MoonPhaseIconPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Moon surface
    canvas.drawCircle(center, radius, Paint()..color = color);

    _drawShadow(canvas, center, radius);
  }

  void _drawShadow(Canvas canvas, Offset center, double radius) {
    final p = phase;

    if (p < 0.01 || p > 0.99) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.92),
      );
      return;
    }

    if ((p - 0.5).abs() < 0.01) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final double termX = radius * cos(p * 2 * pi);
    final double termRx = termX.abs();

    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final ellipseRect = Rect.fromCenter(
      center: center,
      width: termRx * 2,
      height: radius * 2,
    );

    final path = Path();

    if (p < 0.5) {
      path.arcTo(circleRect, -pi / 2, -pi, false);
      path.arcTo(ellipseRect, pi / 2, termX >= 0 ? -pi : pi, false);
    } else {
      path.arcTo(circleRect, -pi / 2, pi, false);
      path.arcTo(ellipseRect, pi / 2, termX >= 0 ? pi : -pi, false);
    }

    path.close();
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(_MoonPhaseIconPainter old) =>
      old.phase != phase || old.color != color;
}