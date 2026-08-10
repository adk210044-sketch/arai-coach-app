import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../widgets/progress_ring.dart';
import '../widgets/pass_probability_card.dart';
import 'paywall_screen.dart';
import '../widgets/quiz_resume_dialog.dart';
import '../widgets/status_legend_dot.dart';
import '../widgets/trend_arrow_icon.dart';
import '../models/category.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _tab = 0; // 0:週 1:月 2:全期間

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final kCategories = appState.categoryStats;
    final totalCorrect = kCategories.fold<int>(0, (s, c) => s + c.correct);
    final totalCount = kCategories.fold<int>(0, (s, c) => s + c.total);
    final overallPct = totalCount == 0
        ? 0
        : (totalCorrect / totalCount * 100).round();
    final passProbability = appState.passProbability;
    final isPremium = appState.isPremium;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '学習の分析 📊',
              style: TextStyle(
                fontSize: AppFontSize.xxxxl,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'AIがあなたの弱点を見つけました',
              style: TextStyle(
                fontSize: AppFontSize.base,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: List.generate(3, (i) {
                const labels = ['週', '月', '全期間'];
                final active = _tab == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.textDim,
                          fontWeight: FontWeight.w600,
                          fontSize: AppFontSize.base,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Overall
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadow.card,
              ),
              child: Row(
                children: [
                  ProgressRing(
                    pct: overallPct.toDouble(),
                    size: 110,
                    stroke: 11,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$overallPct',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const TextSpan(
                                text: '%',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '総合正答率',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFaint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '合格圏まで',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'あと +${(70 - overallPct).clamp(0, 100)}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'もう少しで合格ライン!',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 合格可能性(AI診断)
            PassProbabilityCard(result: passProbability),
            const SizedBox(height: 14),

            // 合格可能性トレンド(プレミアム限定のAI強化機能)
            _passProbabilityTrendSection(context, appState, isPremium),
            const SizedBox(height: 14),

            // AI comment
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.27),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.7,
                          color: AppColors.text,
                        ),
                        children: [
                          TextSpan(
                            text: '関係法令(有害)',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: 'と'),
                          TextSpan(
                            text: '労働衛生(有害)',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: 'が要注意です。\n'),
                          TextSpan(
                            text: '10分間の集中復習セットを用意しました。',
                            style: TextStyle(color: AppColors.textDim),
                          ),
                          TextSpan(
                            text: '\n※「演習」ページでチャレンジしてね',
                            style: TextStyle(
                              color: AppColors.textMute,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '科目別の正答率',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textDim, width: 1.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const Text(
                  '「┃」= 合格ライン(各科目40%以上)',
                  style: TextStyle(
                    fontSize: AppFontSize.xs,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                StatusLegendDot(color: AppColors.textMute, label: '診断中:5問未満'),
                StatusLegendDot(color: AppColors.ng, label: '要復習:60%未満'),
                StatusLegendDot(
                  color: AppColors.yellow,
                  label: 'もう少し:60〜74%',
                ),
                StatusLegendDot(color: AppColors.ok, label: '安全圏:75%以上'),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadow.card,
              ),
              child: Column(
                children: List.generate(kCategories.length, (i) {
                  final cat = kCategories[i];
                  final pct = cat.accuracyPercent;
                  // 4段階の習熟度ステータス。回答数が少ない(5問未満)場合は
                  // 正答率が不安定なため「診断中」として扱う(合格可能性診断と同じ基準)。
                  final hasEnoughData = cat.total >= 5;
                  final String statusLabel;
                  final Color statusColor;
                  final Color barColor;
                  if (!hasEnoughData) {
                    statusLabel = '診断中';
                    statusColor = AppColors.textMute;
                    barColor = AppColors.textMute;
                  } else if (pct < 60) {
                    statusLabel = '要復習';
                    statusColor = AppColors.ng;
                    barColor = AppColors.ng;
                  } else if (pct < 75) {
                    statusLabel = 'もう少し';
                    statusColor = AppColors.yellow;
                    barColor = AppColors.yellow;
                  } else {
                    statusLabel = '安全圏';
                    statusColor = AppColors.ok;
                    barColor = AppColors.ok;
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: i < kCategories.length - 1
                            ? const BorderSide(color: AppColors.borderSoft)
                            : BorderSide.none,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontSize: AppFontSize.md,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: AppFontSize.lg,
                                fontWeight: FontWeight.w700,
                                color: barColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final barWidth = constraints.maxWidth;
                            const passLineRatio = 0.4; // 各科目40%以上が合格基準
                            final markerX = (barWidth * passLineRatio).clamp(
                              0.0,
                              barWidth,
                            );
                            return SizedBox(
                              height: 6,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    child: LinearProgressIndicator(
                                      value: pct / 100,
                                      minHeight: 6,
                                      backgroundColor: AppColors.borderSoft,
                                      valueColor: AlwaysStoppedAnimation(
                                        barColor,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: markerX - 1,
                                    top: -2,
                                    bottom: -2,
                                    child: Container(
                                      width: 2,
                                      color: AppColors.textDim.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // AI優先復習ランキング(プレミアム限定のAI強化機能)
            _weakPointRankingSection(context, appState, isPremium),
            const SizedBox(height: 16),

            const Text(
              '苦手ヒートマップ(週別トレンド)',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _weeklyHeatmapSection(context, appState),
          ],
        ),
      ),
    );
  }

  /// 合格可能性の週次トレンド(直近4週間)。プレミアム限定のAI強化機能。
  /// フリープランではロックされたプレビュー(ブラー風カード)を表示し、アップグレードを促す。
  Widget _passProbabilityTrendSection(
    BuildContext context,
    AppState appState,
    bool isPremium,
  ) {
    final trend = appState.passProbabilityWeeklyTrend;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text(
                '合格可能性トレンド(週次AI診断)',
                style: TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFaint,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!isPremium)
            _lockedPreview(
              context: context,
              message: 'AIが毎週の伸び方を\n自動で分析するよ。\nプレミアムでトレンドの推移が見られるようになるよ。',
              trigger: PaywallTrigger.explanation,
            )
          else if (trend.length < 2)
            const Text(
              'もう少しデータが集まると、週ごとの伸びをAIが分析できるようになるよ。',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textDim,
                height: 1.6,
              ),
            )
          else
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(trend.length, (i) {
                  final v = trend[i];
                  final isLast = i == trend.length - 1;
                  final barColor = v >= 65
                      ? AppColors.ok
                      : (v >= 45 ? AppColors.yellow : AppColors.ng);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$v%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isLast
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isLast
                                  ? AppColors.primary
                                  : AppColors.textMute,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: (v.clamp(5, 100)) * 0.55,
                            decoration: BoxDecoration(
                              color: isLast
                                  ? barColor
                                  : barColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            i == trend.length - 1
                                ? '今週'
                                : '${trend.length - 1 - i}週前',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textMute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// AIによる優先復習ランキング。プレミアム限定のAI強化機能。
  /// 苦手ヒートマップ(週別トレンド)。
  /// 「科目別の正答率」(全期間の累計)とは異なり、直近4週間を1週ずつ区切って
  /// 集計するグリッドにすることで、「最近伸びている/落ち込んでいる科目」を
  /// 一目で確認できるようにする。セルをタップするとその科目の演習に進める。
  Widget _weeklyHeatmapSection(BuildContext context, AppState appState) {
    final weeks = appState.categoryWeeklyHeatmap; // [週(古→新)][科目]
    if (weeks.isEmpty || weeks.first.isEmpty) {
      return const SizedBox.shrink();
    }
    final categories = weeks.first; // 科目の並び(名前取得用)
    const weekLabels = ['3週前', '2週前', '先週', '今週'];

    Color cellColor(CategoryWeekCell cell) {
      if (!cell.hasData) return AppColors.borderSoft;
      final pct = cell.accuracyPercent;
      if (pct < 40) return AppColors.heat3;
      if (pct < 60) return AppColors.heat2;
      if (pct < 80) return AppColors.heat1;
      return AppColors.heat0;
    }

    Color textColorFor(CategoryWeekCell cell) {
      if (!cell.hasData) return AppColors.textMute;
      return cell.accuracyPercent < 60 ? Colors.white : AppColors.text;
    }

    // 前週との比較で「上がっている/下がっている/ほぼ変わらず」を直線の矢印アイコンで
    // 表す(ジグザグのtrending_up等ではなく、シンプルな直線矢印。色は全て白抜きに
    // 統一し、太さを上げて視認性を確保する)。
    // 両方の週にデータがある場合のみ表示(片方でもデータ不足なら比較不能のため非表示)。
    // ±4ポイント以内は「ほぼ変わらず」とみなす。
    TrendDirection? trendArrow(
      CategoryWeekCell current,
      CategoryWeekCell? previous,
    ) {
      if (previous == null || !current.hasData || !previous.hasData) {
        return null;
      }
      final diff = current.accuracyPercent - previous.accuracyPercent;
      if (diff > 4) return TrendDirection.up;
      if (diff < -4) return TrendDirection.down;
      return TrendDirection.flat;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 凡例: 色が濃いほど正答率が低い(苦手)週
          Row(
            children: [
              const Text(
                '得意',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    AppColors.heat0,
                    AppColors.heat1,
                    AppColors.heat2,
                    AppColors.heat3,
                  ].map((c) {
                    return Expanded(
                      child: Container(height: 10, color: c),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '苦手',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '週ごとの正答率を色で表示。セルをタップするとその科目の演習に進めます。',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _trendLegendChip(AppColors.ok, TrendDirection.up),
              const SizedBox(width: 3),
              const Text(
                '前週より上昇',
                style: TextStyle(fontSize: 10, color: AppColors.textDim),
              ),
              const SizedBox(width: 10),
              _trendLegendChip(AppColors.ng, TrendDirection.down),
              const SizedBox(width: 3),
              const Text(
                '前週より下降',
                style: TextStyle(fontSize: 10, color: AppColors.textDim),
              ),
              const SizedBox(width: 10),
              _trendLegendChip(AppColors.textMute, TrendDirection.flat),
              const SizedBox(width: 3),
              const Text(
                'ほぼ変わらず',
                style: TextStyle(fontSize: 10, color: AppColors.textDim),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ヘッダー行(週ラベル): 左に科目名の余白分だけ空けて右詰めで配置
          Row(
            children: [
              const SizedBox(width: 92),
              ...weekLabels.map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMute,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 科目ごとの行: 科目名 + 4週分のセル
          ...List.generate(categories.length, (catIdx) {
            final categoryName = categories[catIdx].categoryName;
            final categoryKey = categories[catIdx].categoryKey;
            return Padding(
              padding: EdgeInsets.only(
                bottom: catIdx < categories.length - 1 ? 6 : 0,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...List.generate(weeks.length, (weekIdx) {
                    final cell = weeks[weekIdx][catIdx];
                    final prevCell = weekIdx > 0
                        ? weeks[weekIdx - 1][catIdx]
                        : null;
                    final arrow = trendArrow(cell, prevCell);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GestureDetector(
                          onTap: () {
                            startQuizSession(
                              context,
                              onStartNew: () =>
                                  context.read<AppState>().startSession(
                                    categoryKey: categoryKey,
                                    count: 10,
                                  ),
                            );
                          },
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: cellColor(cell),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cell.hasData
                                      ? '${cell.accuracyPercent}%'
                                      : '−',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textColorFor(cell),
                                  ),
                                ),
                                if (arrow != null) ...[
                                  const SizedBox(height: 1),
                                  TrendArrowIcon(
                                    direction: arrow,
                                    size: 22,
                                    color: Colors.white,
                                    strokeWidth: 3.5,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 凡例用の矢印チップ。セル内は白抜き矢印のため、白背景の凡例エリアでは
  /// そのままだと見えなくなる。ここでは色付きの小さな丸背景に白矢印を載せることで
  /// 視認性を確保しつつ、セル内表示と同じ矢印デザイン(直線+矢じり)を使う。
  Widget _trendLegendChip(Color bgColor, TrendDirection direction) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: TrendArrowIcon(
        direction: direction,
        size: 12,
        color: Colors.white,
        strokeWidth: 2.2,
      ),
    );
  }

  Widget _weakPointRankingSection(
    BuildContext context,
    AppState appState,
    bool isPremium,
  ) {
    final insights = appState.weakPointInsights;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text(
                'AI優先復習ランキング',
                style: TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFaint,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '正答率と合格基準への影響度から、AIが復習の優先順位を自動で並べ替えるよ',
            style: TextStyle(
              fontSize: AppFontSize.sm,
              color: AppColors.textDim,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (!isPremium)
            _lockedPreview(
              context: context,
              message:
                  '「${insights.isNotEmpty ? insights.first.categoryName : '苦手科目'}」から優先すべき理由を\nAIが解説するよ。\nプレミアムで全ランキングを\n確認できるよ。',
              trigger: PaywallTrigger.explanation,
            )
          else if (insights.isEmpty)
            const Text(
              'まだ解答データが少ないよ。いくつか問題を解くと、AIが優先順位を分析できるようになるよ。',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textDim,
                height: 1.6,
              ),
            )
          else
            Column(
              children: insights.take(5).map((w) {
                final barColor = w.accuracyPercent < 40
                    ? AppColors.ng
                    : (w.accuracyPercent < 60
                          ? AppColors.yellow
                          : AppColors.ok);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: w.rank == 1 ? AppColors.accent : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${w.rank}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: w.rank == 1
                                ? Colors.white
                                : AppColors.textDim,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    w.categoryName,
                                    style: const TextStyle(
                                      fontSize: AppFontSize.md,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${w.accuracyPercent}%',
                                  style: TextStyle(
                                    fontSize: AppFontSize.md,
                                    fontWeight: FontWeight.w800,
                                    color: barColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              w.comment,
                              style: const TextStyle(
                                fontSize: AppFontSize.sm,
                                color: AppColors.textDim,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '推奨: 復習${w.recommendedCount}問',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// フリープラン向けの「機能はあるけどロックされている」プレビューUI。
  /// ぼかし風の見た目 + タップでペイウォールに誘導する。
  Widget _lockedPreview({
    required BuildContext context,
    required String message,
    required PaywallTrigger trigger,
  }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaywallScreen(trigger: trigger)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textDim,
                  height: 1.6,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
