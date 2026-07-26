// daily_plan.dart — 「試験日まで◯日、今日やる問題はこれ」を自動算出するロジック
import '../models/category.dart';

class DailyPlanResult {
  final int targetCount; // 今日やるべき問題数
  final String? categoryKey; // 優先カテゴリ(苦手分野)のキー。nullなら全体からランダム
  final String categoryName; // 表示用カテゴリ名
  final int? daysUntilExam;

  const DailyPlanResult({
    required this.targetCount,
    required this.categoryKey,
    required this.categoryName,
    required this.daysUntilExam,
  });
}

class DailyPlanEngine {
  DailyPlanEngine._();

  static const int _defaultTarget = 15;
  static const int _minTarget = 5;
  static const int _maxTarget = 40;

  /// [totalQuestionsInPool] 受験区分に対応する全問題数
  /// [totalAnsweredOverall] これまでの累計回答数(ざっくりの消化目安として使用)
  /// [daysUntilExam] 試験日までの残り日数(null=未設定)
  /// [categoryStats] カテゴリ別の正答率統計(苦手分野の抽出に使用)
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
        target = _minTarget + 5; // 直前期は10問程度に絞る
      } else {
        target = (remaining / daysUntilExam).ceil();
      }
    }
    target = target.clamp(_minTarget, _maxTarget);

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
    );
  }
}
