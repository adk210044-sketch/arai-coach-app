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
    // 線の端・角を「丸」ではなく「キッチリ角ばった」形にするため、
    // strokeCap/strokeJoinはsquare/miterを使う。矢じりも開いた2本線ではなく
    // 塗りつぶしの三角形(Path.fill)にすることで、シャープな輪郭にする。
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final pad = strokeWidth + 2;
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

    // 矢じり(先端の塗りつぶし三角形)の分だけ軸線を手前で止め、
    // 三角形と軸線が綺麗に繋がるようにする。
    // arrowLenは矢印全体の長さに対する比率で決める(固定値だと、凡例のような
    // 小さいサイズで矢じりが本体の線に対して小さすぎ、棒のように見えてしまう)。
    // 「矢印だとわかりやすい」ように、比率・開き角・上限のいずれも大きめに設定。
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final lineLength = (end - start).distance;
    final arrowLen = math.min(lineLength * 0.62, 12.0);
    const arrowAngle = math.pi / 4.8; // 矢じりの開き角(広いほど三角形が大きく見える)

    final shaftEnd = Offset(
      end.dx - (arrowLen * 0.72) * math.cos(angle),
      end.dy - (arrowLen * 0.72) * math.sin(angle),
    );
    canvas.drawLine(start, shaftEnd, linePaint);

    final p1 = Offset(
      end.dx - arrowLen * math.cos(angle - arrowAngle),
      end.dy - arrowLen * math.sin(angle - arrowAngle),
    );
    final p2 = Offset(
      end.dx - arrowLen * math.cos(angle + arrowAngle),
      end.dy - arrowLen * math.sin(angle + arrowAngle),
    );

    final headPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant _TrendArrowPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
