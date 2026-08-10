// pass_probability_card.dart — 合格可能性を可視化するカード。
// ホーム画面・分析画面の両方で使い回す共通ウィジェット。
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../logic/pass_probability.dart';
import 'progress_ring.dart';
import 'status_legend_dot.dart';

class PassProbabilityCard extends StatelessWidget {
  final PassProbabilityResult result;
  final bool compact;

  const PassProbabilityCard({
    super.key,
    required this.result,
    this.compact = false,
  });

  Color get _ringColor {
    if (result.percent >= 80) return AppColors.ok;
    if (result.percent >= 65) return AppColors.primary;
    if (result.percent >= 45) return AppColors.yellow;
    return AppColors.ng;
  }

  Color get _badgeBg {
    if (result.percent >= 80) return const Color(0xFFDCFCE7);
    if (result.percent >= 65) return AppColors.primaryFaint;
    if (result.percent >= 45) return const Color(0xFFFFF7DC);
    return const Color(0xFFFEE2E2);
  }

  @override
  Widget build(BuildContext context) {
    final ringSize = compact ? 76.0 : 96.0;
    final ring = ProgressRing(
      // データ不足で「診断中」の間はリングを塗らず、未診断であることを
      // 視覚的にも誤解なく伝える(固定値50%が円グラフとして描かれてしまうのを防ぐ)。
      pct: result.hasEnoughData ? result.percent.toDouble() : 0,
      size: ringSize,
      stroke: compact ? 8 : 10,
      color: _ringColor,
      child: result.hasEnoughData
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${result.percent}',
                        style: TextStyle(
                          fontSize: compact ? 20 : 26,
                          fontWeight: FontWeight.w700,
                          color: _ringColor,
                        ),
                      ),
                      TextSpan(
                        text: '%',
                        style: TextStyle(
                          fontSize: compact ? 10 : 13,
                          color: _ringColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: compact ? 18 : 22,
                  color: AppColors.textMute,
                ),
                const SizedBox(height: 2),
                Text(
                  '診断中',
                  style: TextStyle(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMute,
                  ),
                ),
              ],
            ),
    );

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ring,
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '合格可能性',
                      style: TextStyle(
                        fontSize: AppFontSize.base,
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        result.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _ringColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  result.comment,
                  style: TextStyle(
                    fontSize: AppFontSize.base,
                    color: AppColors.text,
                    height: 1.5,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      StatusLegendDot(color: AppColors.ng, label: '要注意:45%未満'),
                      StatusLegendDot(
                        color: AppColors.yellow,
                        label: 'もう一歩:45〜64%',
                      ),
                      StatusLegendDot(
                        color: AppColors.primary,
                        label: '合格圏:65〜79%',
                      ),
                      StatusLegendDot(color: AppColors.ok, label: '安全圏:80%以上'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
