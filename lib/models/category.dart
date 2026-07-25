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
