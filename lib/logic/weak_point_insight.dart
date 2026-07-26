// weak_point_insight.dart — 「AI弱点分析」機能(プレミアム限定)のロジック。
// 科目別正答率を「合格基準(60%)への寄与度」で優先順位付けし、
// 復習の優先度ランキング + 推奨アクションを生成する(Flutter非依存の純粋Dart)。
import '../models/category.dart';

class WeakPointInsight {
  final int rank; // 1が最優先
  final String categoryKey;
  final String categoryName;
  final int accuracyPercent;
  final int answeredCount;
  final String comment; // あらいコーチ風の一言コメント
  final int recommendedCount; // 推奨復習問題数

  const WeakPointInsight({
    required this.rank,
    required this.categoryKey,
    required this.categoryName,
    required this.accuracyPercent,
    required this.answeredCount,
    required this.comment,
    required this.recommendedCount,
  });
}

class WeakPointEngine {
  WeakPointEngine._();

  /// 正答率が低い(かつ回答数が一定以上ある)科目を優先度順に並べ、
  /// 復習の優先順位ランキングを生成する。
  static List<WeakPointInsight> analyze(List<CategoryStat> stats) {
    final answered = stats.where((c) => c.total > 0).toList();
    if (answered.isEmpty) return [];

    // 正答率が低い順にソート(優先度が高い=最も伸ばしやすい/合格基準に寄与する)
    final sorted = [...answered]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    final results = <WeakPointInsight>[];
    for (var i = 0; i < sorted.length; i++) {
      final c = sorted[i];
      final rank = i + 1;
      String comment;
      int recommendedCount;
      if (c.accuracyPercent < 40) {
        comment = '合格基準(40%)に届いていないよ。ここを最優先で固めると合格可能性が大きく上がるよ。';
        recommendedCount = 15;
      } else if (c.accuracyPercent < 60) {
        comment = 'もう少しで合格ラインだよ。あと数問の精度アップで安定するよ。';
        recommendedCount = 10;
      } else if (c.accuracyPercent < 75) {
        comment = '悪くないけど、まだ伸ばせる余地があるよ。';
        recommendedCount = 5;
      } else {
        comment = 'この科目はかなり得意になってきてるよ。維持だけでOK。';
        recommendedCount = 3;
      }
      results.add(
        WeakPointInsight(
          rank: rank,
          categoryKey: c.key,
          categoryName: c.name,
          accuracyPercent: c.accuracyPercent,
          answeredCount: c.total,
          comment: comment,
          recommendedCount: recommendedCount,
        ),
      );
    }
    return results;
  }
}
