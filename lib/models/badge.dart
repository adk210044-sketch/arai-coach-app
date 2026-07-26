// badge.dart — 実績バッジのモデル。
// カテゴリ別(初操作/継続学習/合格率/AI連携)に分類し、獲得済みかどうかを保持する。
enum BadgeCategory { firstAction, streak, passRate, aiIntegration }

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

  const AppBadge({
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
    required this.category,
    required this.unlocked,
  });

  AppBadge unlockedCopy() => AppBadge(
    id: id,
    icon: icon,
    name: name,
    description: description,
    category: category,
    unlocked: true,
  );
}
