// plan.dart — 料金プラン(価格モデル)の定義
// 競合分析(#1〜#8ベンチマーク)を踏まえた価格設定。
// フリー(¥0・広告モデル・過去問50問) / 月額プレミアム(¥1,200・サブスク) /
// 3か月集中パック(¥2,600・3か月ごとのサブスク)
// 両有料プランともGoogle Play側で「7日間無料トライアル」オファーを設定し、
// 「無料トライアルを始める」の入口から選んだ方のプランへトライアル付きで加入できる。

import 'package:flutter/material.dart';

enum PlanTier { free, premium, intensivePack }

extension PlanTierX on PlanTier {
  String get label {
    switch (this) {
      case PlanTier.free:
        return 'フリープラン';
      case PlanTier.premium:
        return '月額プレミアム';
      case PlanTier.intensivePack:
        return '3か月集中パック';
    }
  }

  String get shortLabel {
    switch (this) {
      case PlanTier.free:
        return 'FREE';
      case PlanTier.premium:
        return 'PREMIUM';
      case PlanTier.intensivePack:
        return 'PACK';
    }
  }
}

/// プランのカタログ情報(表示用の静的データ)
class PlanInfo {
  final PlanTier tier;
  final String priceLabel; // 例: '¥1,200'
  final String periodLabel; // 例: '/月'
  final String? badge; // 例: 'おすすめ ⭐'
  final String subtitle;
  final List<String> features;
  final bool hasFreeTrial;
  final int? trialDays;

  const PlanInfo({
    required this.tier,
    required this.priceLabel,
    required this.periodLabel,
    this.badge,
    required this.subtitle,
    required this.features,
    this.hasFreeTrial = false,
    this.trialDays,
  });

  String get label => tier.label;
}

const Map<PlanTier, PlanInfo> kPlanCatalog = {
  PlanTier.free: PlanInfo(
    tier: PlanTier.free,
    priceLabel: '¥0',
    periodLabel: '',
    subtitle: '過去問50問からお試しできるよ',
    features: ['過去問 50問まで利用可能', '一問一答機能', '苦手復習機能', 'スキマ学習機能', '広告が表示されるよ'],
  ),
  PlanTier.premium: PlanInfo(
    tier: PlanTier.premium,
    priceLabel: '¥1,200',
    periodLabel: '/月',
    subtitle: 'あらいコーチが毎日そばで分析&コーチングするよ',
    features: [
      '🧠 AIが週次で合格可能性を継続診断',
      '🎯 AI優先復習ランキングで弱点を自動特定',
      '🦝 あらいコーチにAI相談し放題\n(※ユーザー側でGemini連携が必要)',
      '📖 令和元年以降の過去問がすべて解放',
      '📝 模擬試験(フル・ミニ)が使える',
      '💡 AI解説をすべて閲覧できる',
      '🚫 広告なし',
      '毎月自動更新(いつでも解約OK)',
    ],
    hasFreeTrial: true,
    trialDays: 7,
  ),
  PlanTier.intensivePack: PlanInfo(
    tier: PlanTier.intensivePack,
    priceLabel: '¥2,600',
    periodLabel: '/3か月',
    badge: 'おすすめ ⭐',
    subtitle: '直近の試験に向けて、AI×コーチで一気に仕上げる',
    features: [
      '🧠 AIが週次で合格可能性を継続診断',
      '🎯 AI優先復習ランキングで弱点を自動特定',
      '🦝 あらいコーチにAI相談し放題\n(※ユーザー側でGemini連携が必要)',
      '📖 令和元年以降の過去問がすべて解放',
      '📝 模擬試験(フル・ミニ)が使える',
      '💡 AI解説をすべて閲覧できる',
      '🚫 広告なし',
      '3か月ごとに自動更新(いつでも解約OK)',
    ],
    hasFreeTrial: true,
    trialDays: 7,
  ),
};

/// プラン間で機能を比較するための一覧(アイコン付きマトリクス表示用)。
/// 「プランの違いが一目でわかる」比較表を作るための静的データ。
enum FeatureLevel {
  /// 利用不可(✕)
  none,

  /// 制限付きで利用可(△)
  partial,

  /// フルで利用可(✓)
  full,
}

class PlanFeatureRow {
  final IconData icon;
  final String label;
  final Map<PlanTier, FeatureLevel> level;
  final Map<PlanTier, String>? valueLabel; // レベルの代わりに短い文言を表示したい場合

  const PlanFeatureRow({
    required this.icon,
    required this.label,
    required this.level,
    this.valueLabel,
  });
}

/// 静的な(受験区分に依存しない)デフォルト表示用。
/// 実際の画面では [buildPlanFeatureMatrix] を使い、現在の受験区分の
/// 実問題数を反映した動的な比較表を生成することを推奨する。
const List<PlanFeatureRow> kPlanFeatureMatrix = [
  PlanFeatureRow(
    icon: Icons.menu_book_outlined,
    label: '過去問',
    level: {
      PlanTier.free: FeatureLevel.partial,
      PlanTier.premium: FeatureLevel.full,
      PlanTier.intensivePack: FeatureLevel.full,
    },
    valueLabel: {
      PlanTier.free: '50問',
      PlanTier.premium: '全814問\n(R1以降)',
      PlanTier.intensivePack: '全814問\n(R1以降)',
    },
  ),
  PlanFeatureRow(
    icon: Icons.style_outlined,
    label: '一問一答',
    level: {
      PlanTier.free: FeatureLevel.partial,
      PlanTier.premium: FeatureLevel.full,
      PlanTier.intensivePack: FeatureLevel.full,
    },
    valueLabel: {
      PlanTier.free: '50問限定',
      PlanTier.premium: '全問対応',
      PlanTier.intensivePack: '全問対応',
    },
  ),
  PlanFeatureRow(
    icon: Icons.replay_circle_filled_outlined,
    label: '苦手復習',
    level: {
      PlanTier.free: FeatureLevel.partial,
      PlanTier.premium: FeatureLevel.full,
      PlanTier.intensivePack: FeatureLevel.full,
    },
    valueLabel: {
      PlanTier.free: 'シンプル版',
      PlanTier.premium: 'AI優先復習',
      PlanTier.intensivePack: 'AI優先復習',
    },
  ),
  PlanFeatureRow(
    icon: Icons.bolt_outlined,
    label: 'スキマ学習',
    level: {
      PlanTier.free: FeatureLevel.partial,
      PlanTier.premium: FeatureLevel.full,
      PlanTier.intensivePack: FeatureLevel.full,
    },
    valueLabel: {
      PlanTier.free: '50問限定',
      PlanTier.premium: '全問対応',
      PlanTier.intensivePack: '全問対応',
    },
  ),
  PlanFeatureRow(
    icon: Icons.edit_note_outlined,
    label: '模擬試験',
    level: {
      PlanTier.free: FeatureLevel.none,
      PlanTier.premium: FeatureLevel.full,
      PlanTier.intensivePack: FeatureLevel.full,
    },
  ),
  PlanFeatureRow(
    icon: Icons.psychology_alt_outlined,
    label: 'AI解説',
    level: {
      PlanTier.free: FeatureLevel.partial,
      PlanTier.premium: FeatureLevel.full,
      PlanTier.intensivePack: FeatureLevel.full,
    },
    valueLabel: {
      PlanTier.free: '一部のみ',
      PlanTier.premium: '全文',
      PlanTier.intensivePack: '全文',
    },
  ),
  PlanFeatureRow(
    icon: Icons.campaign_outlined,
    label: '広告',
    level: {
      PlanTier.free: FeatureLevel.none,
      PlanTier.premium: FeatureLevel.full,
      PlanTier.intensivePack: FeatureLevel.full,
    },
    valueLabel: {
      PlanTier.free: '表示あり',
      PlanTier.premium: 'なし',
      PlanTier.intensivePack: 'なし',
    },
  ),
];

/// 現在の受験区分の実問題数を反映した比較表データを生成する。
/// [totalQuestionCount] にはその受験区分(第一種/第二種)の過去問総数を渡す。
/// [freeQuestionLimit] にはフリープランの上限問題数(通常50)を渡す。
List<PlanFeatureRow> buildPlanFeatureMatrix({
  required int totalQuestionCount,
  required int freeQuestionLimit,
}) {
  return [
    PlanFeatureRow(
      icon: Icons.menu_book_outlined,
      label: '過去問',
      level: const {
        PlanTier.free: FeatureLevel.partial,
        PlanTier.premium: FeatureLevel.full,
        PlanTier.intensivePack: FeatureLevel.full,
      },
      valueLabel: {
        PlanTier.free: '$freeQuestionLimit問',
        PlanTier.premium: '全$totalQuestionCount問\n(R1以降)',
        PlanTier.intensivePack: '全$totalQuestionCount問\n(R1以降)',
      },
    ),
    PlanFeatureRow(
      icon: Icons.style_outlined,
      label: '一問一答',
      level: const {
        PlanTier.free: FeatureLevel.partial,
        PlanTier.premium: FeatureLevel.full,
        PlanTier.intensivePack: FeatureLevel.full,
      },
      valueLabel: const {
        PlanTier.free: '50問限定',
        PlanTier.premium: '全問対応',
        PlanTier.intensivePack: '全問対応',
      },
    ),
    PlanFeatureRow(
      icon: Icons.replay_circle_filled_outlined,
      label: '苦手復習',
      level: const {
        PlanTier.free: FeatureLevel.partial,
        PlanTier.premium: FeatureLevel.full,
        PlanTier.intensivePack: FeatureLevel.full,
      },
      valueLabel: const {
        PlanTier.free: 'シンプル版',
        PlanTier.premium: 'AI優先復習',
        PlanTier.intensivePack: 'AI優先復習',
      },
    ),
    PlanFeatureRow(
      icon: Icons.bolt_outlined,
      label: 'スキマ学習',
      level: const {
        PlanTier.free: FeatureLevel.partial,
        PlanTier.premium: FeatureLevel.full,
        PlanTier.intensivePack: FeatureLevel.full,
      },
      valueLabel: const {
        PlanTier.free: '50問限定',
        PlanTier.premium: '全問対応',
        PlanTier.intensivePack: '全問対応',
      },
    ),
    const PlanFeatureRow(
      icon: Icons.edit_note_outlined,
      label: '模擬試験',
      level: {
        PlanTier.free: FeatureLevel.none,
        PlanTier.premium: FeatureLevel.full,
        PlanTier.intensivePack: FeatureLevel.full,
      },
    ),
    const PlanFeatureRow(
      icon: Icons.psychology_alt_outlined,
      label: 'AI解説',
      level: {
        PlanTier.free: FeatureLevel.partial,
        PlanTier.premium: FeatureLevel.full,
        PlanTier.intensivePack: FeatureLevel.full,
      },
      valueLabel: {
        PlanTier.free: '一部のみ',
        PlanTier.premium: '全文',
        PlanTier.intensivePack: '全文',
      },
    ),
    const PlanFeatureRow(
      icon: Icons.campaign_outlined,
      label: '広告',
      level: {
        PlanTier.free: FeatureLevel.none,
        PlanTier.premium: FeatureLevel.full,
        PlanTier.intensivePack: FeatureLevel.full,
      },
      valueLabel: {
        PlanTier.free: '表示あり',
        PlanTier.premium: 'なし',
        PlanTier.intensivePack: 'なし',
      },
    ),
  ];
}
