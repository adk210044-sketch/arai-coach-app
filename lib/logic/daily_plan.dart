// daily_plan.dart — 「試験日まで◯日、今日やる問題はこれ」を自動算出するロジック
import '../models/category.dart';

class DailyPlanResult {
  final int targetCount; // 今日やるべき問題数(合計)
  final String? categoryKey; // 最重点カテゴリ(苦手分野)のキー。nullなら全体からランダム
  final String categoryName; // 表示用カテゴリ名(最重点カテゴリ)
  final int? daysUntilExam;

  /// カテゴリキー → 今日の出題数。全カテゴリに最低配分 + 苦手カテゴリへの重点配分を反映。
  final Map<String, int> categoryDistribution;

  const DailyPlanResult({
    required this.targetCount,
    required this.categoryKey,
    required this.categoryName,
    required this.daysUntilExam,
    this.categoryDistribution = const {},
  });
}

class DailyPlanEngine {
  DailyPlanEngine._();

  static const int _defaultTarget = 15;
  static const int _minTarget = 10;
  static const int _maxTarget = 40;

  /// 各カテゴリに最低限保証する出題数。
  /// 「今日のタスク」だけをこなしても全カテゴリをまんべんなく触れられるようにするための下限。
  static const int _perCategoryMin = 3;

  /// [totalQuestionsInPool] 受験区分に対応する全問題数
  /// [totalAnsweredOverall] これまでの累計回答数(ざっくりの消化目安として使用)
  /// [daysUntilExam] 試験日までの残り日数(null=未設定)
  /// [categoryStats] カテゴリ別の正答率統計(苦手分野の抽出・配分に使用)
  static DailyPlanResult computeToday({
    required int totalQuestionsInPool,
    required int totalAnsweredOverall,
    required int? daysUntilExam,
    required List<CategoryStat> categoryStats,
  }) {
    int target;
    if (daysUntilExam == null || daysUntilExam <= 0) {
      target = _defaultTarget;
    } else {
      final remaining = (totalQuestionsInPool - totalAnsweredOverall).clamp(
        0,
        totalQuestionsInPool,
      );
      // 残り問題数を残り日数で割って「今日のペース」を算出。
      // 試験直前(7日以内)は苦手つぶしを優先し、量よりも的を絞る。
      if (daysUntilExam <= 7) {
        target = _minTarget; // 直前期は最低ライン付近に絞る
      } else {
        target = (remaining / daysUntilExam).ceil();
      }
    }

    // 全カテゴリに最低3問ずつ配るためのベース必要数。
    // カテゴリ数が多い受験区分ほど、これが実質的な最低ラインになる。
    final numCategories = categoryStats.isNotEmpty ? categoryStats.length : 1;
    final baseTotal = _perCategoryMin * numCategories;

    target = target.clamp(_minTarget, _maxTarget);
    if (target < baseTotal) target = baseTotal;

    // ─── カテゴリ別配分 ──────────────────────
    // 1) 全カテゴリへ最低3問を配分
    final distribution = <String, int>{
      for (final c in categoryStats) c.key: _perCategoryMin,
    };

    // 2) 残りを「苦手度(誤答率)」で重み付けして配分。
    //    未回答カテゴリは中間的な重み(0.5)を与え、データ不足で配分0にならないようにする。
    final remainingToAllocate = target - baseTotal;
    if (remainingToAllocate > 0 && categoryStats.isNotEmpty) {
      final weights = categoryStats.map((c) {
        if (c.total == 0) return 0.5;
        return (1 - c.accuracy).clamp(0.1, 1.0);
      }).toList();
      final totalWeight = weights.fold<double>(0, (a, b) => a + b);

      final shares = List<int>.filled(categoryStats.length, 0);
      var allocated = 0;
      if (totalWeight > 0) {
        for (var i = 0; i < categoryStats.length; i++) {
          final share = (remainingToAllocate * weights[i] / totalWeight)
              .floor();
          shares[i] = share;
          allocated += share;
        }
      }
      // 端数(切り捨て分)は、苦手な(重みが大きい)カテゴリから順に1問ずつ配る。
      var leftover = remainingToAllocate - allocated;
      final order = List<int>.generate(categoryStats.length, (i) => i)
        ..sort((a, b) => weights[b].compareTo(weights[a]));
      var idx = 0;
      while (leftover > 0 && order.isNotEmpty) {
        shares[order[idx % order.length]] += 1;
        leftover--;
        idx++;
      }

      for (var i = 0; i < categoryStats.length; i++) {
        final key = categoryStats[i].key;
        distribution[key] = (distribution[key] ?? 0) + shares[i];
      }
    }

    // 表示用の「最重点カテゴリ」(配分数が最も多い = 最も苦手なカテゴリ)を求める。
    CategoryStat? weakest;
    for (final c in categoryStats) {
      if (c.total == 0) continue;
      if (weakest == null || c.accuracy < weakest.accuracy) {
        weakest = c;
      }
    }

    return DailyPlanResult(
      targetCount: target,
      categoryKey: weakest?.key,
      categoryName: weakest?.name ?? '全体復習',
      daysUntilExam: daysUntilExam,
      categoryDistribution: distribution,
    );
  }
}
