// badge.dart — 実績バッジのモデル。
// カテゴリ別(初操作/継続学習/合格率/AI連携)に分類し、獲得済みかどうかを保持する。
enum BadgeCategory { firstAction, streak, passRate, aiIntegration }

/// バッジの見た目のランク(メダルの色)。
/// 継続バッジ・合格力バッジなど「段階的に格上げされる」系列では、
/// silver(下位) → light(淡いブルー・中位) → vivid(濃いブルー・上位/最高評価)
/// の順でランクが上がる(濃いブルーが最も良い色)。
/// 挑戦バッジ・AI連携バッジなど「優先度のない」単発の達成バッジについては
/// このランク順に縛られず、どの色を割り当ててもよい。
enum BadgeTier { light, vivid, silver }

extension BadgeCategoryX on BadgeCategory {
  String get label {
    switch (this) {
      case BadgeCategory.firstAction:
        return '挑戦バッジ';
      case BadgeCategory.streak:
        return '継続バッジ';
      case BadgeCategory.passRate:
        return '合格力バッジ';
      case BadgeCategory.aiIntegration:
        return 'AI連携バッジ';
    }
  }

  String get emoji {
    switch (this) {
      case BadgeCategory.firstAction:
        return '🚀';
      case BadgeCategory.streak:
        return '🔥';
      case BadgeCategory.passRate:
        return '📈';
      case BadgeCategory.aiIntegration:
        return '🦝';
    }
  }
}

class AppBadge {
  final String id;
  final String icon;
  final String name;
  final String description;
  final BadgeCategory category;
  final bool unlocked;
  final BadgeTier tier;

  const AppBadge({
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
    required this.category,
    required this.unlocked,
    this.tier = BadgeTier.light,
  });

  AppBadge unlockedCopy() => AppBadge(
    id: id,
    icon: icon,
    name: name,
    description: description,
    category: category,
    unlocked: true,
    tier: tier,
  );
}
