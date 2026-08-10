class CategoryStat {
  final String key;
  final String name;
  final int total;
  final int correct;
  final bool weak;

  const CategoryStat({
    required this.key,
    required this.name,
    required this.total,
    required this.correct,
    required this.weak,
  });

  double get accuracy => total == 0 ? 0 : correct / total;
  int get accuracyPercent => (accuracy * 100).round();
}

/// 1つの科目・1つの週分の正答率セル(苦手ヒートマップの週次トレンド表示用)。
/// 「科目別の正答率」(全期間の累計)とは異なり、その週【のみ】の回答データを
/// 集計するため、直近の伸び・落ち込みを科目ごとに比較できる。
class CategoryWeekCell {
  final String categoryKey;
  final String categoryName;
  final int total; // その週の回答数
  final int correct; // その週の正解数

  const CategoryWeekCell({
    required this.categoryKey,
    required this.categoryName,
    required this.total,
    required this.correct,
  });

  /// その週にまだ演習していない(データ不足)場合はtrue。
  bool get hasData => total > 0;
  double get accuracy => total == 0 ? 0 : correct / total;
  int get accuracyPercent => (accuracy * 100).round();
}
