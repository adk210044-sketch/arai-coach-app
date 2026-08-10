// trend_arrow_icon.dart — 苦手ヒートマップ(週別トレンド)の各セルに表示する
// 「前週比」の矢印アイコン。
// Material Icons の trending_up/down/flat はジグザグ(株価チャート風)の矢印で
// 見づらいという指摘のため、CustomPaint で直線の矢印(線+矢じり)を描画する。
// 太さ(strokeWidth)を自由に調整できるようにし、視認性を確保する。
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum TrendDirection { up, down, flat }

class TrendArrowIcon extends StatelessWidget {
  final TrendDirection direction;
  final double size;
  final Color color;
  final double strokeWidth;

  const TrendArrowIcon({
    super.key,
    required this.direction,
    this.size = 22,
    this.color = Colors.white,
    this.strokeWidth = 3.2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TrendArrowPainter(
          direction: direction,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _TrendArrowPainter extends CustomPainter {
  final TrendDirection direction;
  final Color color;
  final double strokeWidth;

  _TrendArrowPainter({
    required this.direction,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pad = strokeWidth + 1;
    final w = size.width;
    final h = size.height;

    Offset start;
    Offset end;
    switch (direction) {
      case TrendDirection.up:
        start = Offset(pad, h - pad);
        end = Offset(w - pad, pad);
        break;
      case TrendDirection.down:
        start = Offset(pad, pad);
        end = Offset(w - pad, h - pad);
        break;
      case TrendDirection.flat:
        start = Offset(pad, h / 2);
        end = Offset(w - pad, h / 2);
        break;
    }

    // 本線(直線の矢印の軸)
    canvas.drawLine(start, end, paint);

    // 矢じり(先端に「く」の字型を描く)
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowLen = 6.0;
    const arrowAngle = math.pi / 6.5; // 矢じりの開き角

    final p1 = Offset(
      end.dx - arrowLen * math.cos(angle - arrowAngle),
      end.dy - arrowLen * math.sin(angle - arrowAngle),
    );
    final p2 = Offset(
      end.dx - arrowLen * math.cos(angle + arrowAngle),
      end.dy - arrowLen * math.sin(angle + arrowAngle),
    );

    canvas.drawLine(end, p1, paint);
    canvas.drawLine(end, p2, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendArrowPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
