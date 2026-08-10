// status_legend_dot.dart — 「科目別の正答率」の4段階ステータス
// (診断中/要復習/もう少し/安全圏)の凡例に使う、色付き丸+ラベルの小さな行ウィジェット。
// analysis_screen.dart(分析ページ)と study_screen.dart(演習ページ)の両方から
// 参照することで、表記・見た目を統一する。
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class StatusLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const StatusLegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: AppFontSize.xs, color: AppColors.textDim),
        ),
      ],
    );
  }
}
