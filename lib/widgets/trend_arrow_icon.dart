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

    // 中心点を基準に、方向ベクトル(正規化済み)×共通の半長(halfLen)で
    // start/endを決める。以前はup/downが正方形の対角線(√2倍長い)を使い、
    // flatが幅方向のみ(短い)を使っていたため、横矢印だけ小さく見える
    // 不揃いが発生していた。この方式なら全方向で線の長さが必ず揃う。
    final center = Offset(w / 2, h / 2);
    final halfLen = math.min(w, h) / 2 - pad;

    Offset dir;
    switch (direction) {
      case TrendDirection.up:
        dir = const Offset(1, -1);
        break;
      case TrendDirection.down:
        dir = const Offset(1, 1);
        break;
      case TrendDirection.flat:
        dir = const Offset(1, 0);
        break;
    }
    final normDir = dir / dir.distance;
    final start = center - normDir * halfLen;
    final end = center + normDir * halfLen;

    // 矢じり(先端の塗りつぶし三角形)の分だけ軸線を手前で止め、
    // 三角形と軸線が綺麗に繋がるようにする。
    // arrowLenは矢印全体の長さに対する比率で決める(固定値だと、凡例のような
    // 小さいサイズで矢じりが本体の線に対して小さすぎ、棒のように見えてしまう)。
    // 「矢印だとわかりやすい」ように、比率・開き角・上限のいずれも大きめに設定。
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final lineLength = (end - start).distance;
    final arrowLen = math.min(lineLength * 0.68, 16.0);
    const arrowAngle = math.pi / 4.4; // 矢じりの開き角(広いほど三角形が大きく見える)

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
