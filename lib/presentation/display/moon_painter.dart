import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders the moon as a circle filled with the full-moon photo, overlaid
/// with a shadow that represents the current illumination phase.
class MoonPainter extends CustomPainter {
  final ui.Image image;

  /// Moon phase 0–1 (0 = new moon, 0.5 = full moon, 1 = new moon again).
  final double phase;

  MoonPainter({required this.image, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // Clip everything to the moon circle.
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // Draw the full-moon photo scaled to fill the circle.
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromCircle(center: center, radius: radius);
    canvas.drawImageRect(image, src, dst, Paint());

    // Draw the shadow overlay.
    _drawShadow(canvas, center, radius);
  }

  void _drawShadow(Canvas canvas, Offset center, double radius) {
    final p = phase;

    // New moon: completely dark.
    if (p < 0.01 || p > 0.99) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.92),
      );
      return;
    }

    // Full moon: no shadow.
    if ((p - 0.5).abs() < 0.01) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    // Horizontal semi-axis of the terminator ellipse.
    // cos(phase × 2π): +radius at new moon, 0 at quarter, -radius at full.
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
      // Waxing: dark on the left.
      // Arc 1: left semicircle — start at top, sweep −π (CCW in screen space
      //         = going left first, then down to bottom).
      path.arcTo(circleRect, -pi / 2, -pi, false);

      // Arc 2: half-ellipse from bottom back to top.
      //   termX > 0 → crescent → right side of ellipse (sweep −π, CCW).
      //   termX < 0 → gibbous  → left  side of ellipse (sweep +π, CW).
      final ellipseSweep = termX >= 0 ? -pi : pi;
      path.arcTo(ellipseRect, pi / 2, ellipseSweep, false);
    } else {
      // Waning: dark on the right.
      // Arc 1: right semicircle — start at top, sweep +π (CW in screen space
      //         = going right first, then down to bottom).
      path.arcTo(circleRect, -pi / 2, pi, false);

      // Arc 2: half-ellipse from bottom back to top.
      //   termX < 0 → gibbous  → right side of ellipse (sweep −π, CCW).
      //   termX > 0 → crescent → left  side of ellipse (sweep +π, CW).
      final ellipseSweep = termX >= 0 ? pi : -pi;
      path.arcTo(ellipseRect, pi / 2, ellipseSweep, false);
    }

    path.close();
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(MoonPainter old) =>
      old.phase != phase || old.image != image;
}
