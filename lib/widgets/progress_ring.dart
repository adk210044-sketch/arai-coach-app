import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class ProgressRing extends StatelessWidget {
  final double pct; // 0-100
  final double size;
  final double stroke;
  final Color color;
  final Color? trackColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.pct,
    this.size = 110,
    this.stroke = 11,
    this.color = AppColors.primary,
    this.trackColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTrackColor = trackColor ?? AppColors.borderSoft;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  pct: value,
                  stroke: stroke,
                  color: color,
                  trackColor: resolvedTrackColor,
                ),
              ),
              if (child != null) child!,
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final double stroke;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.pct,
    required this.stroke,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * (pct / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.pct != pct || oldDelegate.color != color;
}
