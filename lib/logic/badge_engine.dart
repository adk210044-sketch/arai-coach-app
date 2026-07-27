// badge_engine.dart — 実績バッジの定義と、現在の学習データからの判定ロジック。
//
// バッジは「一度獲得したら失わない」設計とするため、
// このファイルでは「現在の状態から見て達成条件を満たしているか」だけを判定し、
// 実際の獲得記録・永続化は AppState / LocalStore が担う。
import '../models/badge.dart';

class BadgeCondition {
  final String id;
  final String icon;
  final String name;
  final String description;
  final BadgeCategory category;
  final BadgeTier tier;

  const BadgeCondition({
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
    required this.category,
    this.tier = BadgeTier.light,
  });
}

class BadgeEngine {
  BadgeEngine._();

  /// 継続学習バッジのしきい値(日数)。3か月の集中パックを想定した範囲で設定。
  static const List<int> streakMilestones = [3, 5, 10, 20, 30, 40, 60, 90];

  /// 合格率バッジのしきい値(%)。
  static const List<int> passRateMilestones = [40, 50, 60, 70, 80];

  /// 全バッジ定義(表示順)。
  static final List<BadgeCondition> all = [
    // ─── 挑戦バッジ(各機能の初操作) ──────────────────────
    const BadgeCondition(
      id: 'first_answer',
      icon: '🌱',
      name: 'はじめの一問',
      description: '演習問題に初めて挑戦したよ',
      category: BadgeCategory.firstAction,
      tier: BadgeTier.light,
    ),
    const BadgeCondition(
      id: 'first_gap_study',
      icon: '⚡',
      name: 'スキマ学習デビュー',
      description: 'スキマ学習を初めて実施したよ',
      category: BadgeCategory.firstAction,
      tier: BadgeTier.light,
    ),
    const BadgeCondition(
      id: 'first_weak_review',
      icon: '🧠',
      name: '苦手復習デビュー',
      description: '苦手復習を初めて実施したよ',
      category: BadgeCategory.firstAction,
      tier: BadgeTier.light,
    ),
    const BadgeCondition(
      id: 'first_mock_exam',
      icon: '📝',
      name: '模擬試験デビュー',
      description: '模擬試験を初めて実施したよ',
      category: BadgeCategory.firstAction,
      tier: BadgeTier.light,
    ),
    const BadgeCondition(
      id: 'first_coach_chat',
      icon: '💬',
      name: 'あらいコーチに初相談',
      description: 'あらいコーチに初めて相談したよ',
      category: BadgeCategory.firstAction,
      tier: BadgeTier.light,
    ),
    const BadgeCondition(
      id: 'first_bookmark',
      icon: '🔖',
      name: '保存デビュー',
      description: '問題を初めて保存(ブックマーク)したよ',
      category: BadgeCategory.firstAction,
      tier: BadgeTier.light,
    ),

    // ─── 継続学習バッジ(連続ログイン・学習日数) ──────────────────────
    BadgeCondition(
      id: 'streak_3',
      icon: '🔥',
      name: '3日連続',
      description: '3日連続で学習したよ',
      category: BadgeCategory.streak,
      tier: BadgeTier.silver,
    ),
    BadgeCondition(
      id: 'streak_5',
      icon: '🔥',
      name: '5日連続',
      description: '5日連続で学習したよ',
      category: BadgeCategory.streak,
      tier: BadgeTier.silver,
    ),
    BadgeCondition(
      id: 'streak_10',
      icon: '🔥',
      name: '10日連続',
      description: '10日連続で学習したよ',
      category: BadgeCategory.streak,
      tier: BadgeTier.silver,
    ),
    BadgeCondition(
      id: 'streak_20',
      icon: '⚡',
      name: '20日連続',
      description: '20日連続で学習したよ。リズムができてきたね',
      category: BadgeCategory.streak,
      tier: BadgeTier.light,
    ),
    BadgeCondition(
      id: 'streak_30',
      icon: '⚡',
      name: '30日連続',
      description: '30日連続で学習したよ。もう習慣だね',
      category: BadgeCategory.streak,
      tier: BadgeTier.light,
    ),
    BadgeCondition(
      id: 'streak_40',
      icon: '🌟',
      name: '40日連続',
      description: '40日連続で学習したよ。着実に力がついてるよ',
      category: BadgeCategory.streak,
      tier: BadgeTier.light,
    ),
    BadgeCondition(
      id: 'streak_60',
      icon: '🌟',
      name: '60日連続',
      description: '60日連続で学習したよ。すごい継続力だね',
      category: BadgeCategory.streak,
      tier: BadgeTier.vivid,
    ),
    BadgeCondition(
      id: 'streak_90',
      icon: '👑',
      name: '90日連続',
      description: '90日連続で学習したよ。3か月やり切ったのは本当にすごいよ',
      category: BadgeCategory.streak,
      tier: BadgeTier.vivid,
    ),

    // ─── 合格力バッジ(合格可能性診断の到達値) ──────────────────────
    BadgeCondition(
      id: 'pass_rate_40',
      icon: '🎯',
      name: '合格可能性40%',
      description: '合格可能性診断が40%に達したよ',
      category: BadgeCategory.passRate,
      tier: BadgeTier.silver,
    ),
    BadgeCondition(
      id: 'pass_rate_50',
      icon: '🎯',
      name: '合格可能性50%',
      description: '合格可能性診断が50%に達したよ',
      category: BadgeCategory.passRate,
      tier: BadgeTier.silver,
    ),
    BadgeCondition(
      id: 'pass_rate_60',
      icon: '📈',
      name: '合格可能性60%',
      description: '合格可能性診断が60%(合格圏)に達したよ',
      category: BadgeCategory.passRate,
      tier: BadgeTier.light,
    ),
    BadgeCondition(
      id: 'pass_rate_70',
      icon: '📈',
      name: '合格可能性70%',
      description: '合格可能性診断が70%に達したよ',
      category: BadgeCategory.passRate,
      tier: BadgeTier.light,
    ),
    BadgeCondition(
      id: 'pass_rate_80',
      icon: '🏆',
      name: '合格可能性80%(安全圏)',
      description: '合格可能性診断が80%(安全圏)に達したよ',
      category: BadgeCategory.passRate,
      tier: BadgeTier.vivid,
    ),

    // ─── AI連携バッジ ──────────────────────
    BadgeCondition(
      id: 'gemini_linked',
      icon: '🦝',
      name: 'あらいコーチAI連携',
      description: 'Gemini APIキーを登録して、あらいコーチと自由に会話できるようになったよ',
      category: BadgeCategory.aiIntegration,
      tier: BadgeTier.vivid,
    ),
  ];

  static BadgeCondition byId(String id) =>
      all.firstWhere((b) => b.id == id, orElse: () => all.first);

  /// 継続日数から、新たに達成したストリークバッジIDを返す(達成済みチェックは呼び出し元で行う)。
  static List<String> streakBadgeIdsForDays(int days) {
    return streakMilestones
        .where((m) => days >= m)
        .map((m) => 'streak_$m')
        .toList();
  }

  /// 合格可能性(%)から、新たに達成した合格率バッジIDを返す。
  static List<String> passRateBadgeIdsForPercent(int percent) {
    return passRateMilestones
        .where((m) => percent >= m)
        .map((m) => 'pass_rate_$m')
        .toList();
  }
}
