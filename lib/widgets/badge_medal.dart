// badge_medal.dart — 実績バッジを「メダル」らしい質感で表示するウィジェット。
// AI画像生成モデルで直接生成した金属メダル画像(assets/badges/)を、
// バッジごとに専用の1枚として表示する方式。
// (以前はティア共通の土台画像に絵文字アイコンを重ねる方式だったが、
//  月桂冠+線画アイコンを一体で刻印したメダル画像そのものを使う方式に変更した)
// 金銀銅ではなく、本アプリのトンマナ(スタサプ的ブルー)に合わせて
// ライトブルー/ビビッドブルー/シルバーの3ティアでランクを表現する。
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../models/badge.dart';

class BadgeMedal extends StatelessWidget {
  /// バッジID(badge_engine.dart の BadgeCondition.id と一致)。
  /// このIDから、専用の刻印済みメダル画像を1枚選ぶ。
  final String badgeId;
  final bool unlocked;
  final double size;

  const BadgeMedal({
    super.key,
    required this.badgeId,
    required this.unlocked,
    this.size = 56,
  });

  /// バッジID → メダル画像ファイル名(拡張子なし)のマッピング。
  /// 全20種のバッジ条件を、色(tier)とアイコンの組み合わせで14枚の画像に割り当てる。
  /// (系統の近いバッジ同士は画像を共用している: 例) first_gap_study と
  ///  first_coach_chat はどちらも「会話」を表す light_chat を共用)
  static const Map<String, String> _assetByBadgeId = {
    // 挑戦バッジ
    'first_answer': 'light_seedling',
    'first_gap_study': 'light_chat',
    'first_weak_review': 'light_brain',
    'first_mock_exam': 'light_memo',
    'first_coach_chat': 'light_chat',
    'first_bookmark': 'light_bookmark',
    // 継続バッジ
    'streak_3': 'silver_flame',
    'streak_5': 'silver_flame',
    'streak_10': 'silver_flame',
    'streak_20': 'light_lightning',
    'streak_30': 'light_lightning',
    'streak_40': 'light_star',
    'streak_60': 'vivid_star',
    'streak_90': 'vivid_crown',
    // 合格力バッジ
    'pass_rate_40': 'silver_target',
    'pass_rate_50': 'silver_target',
    'pass_rate_60': 'light_chart',
    'pass_rate_70': 'light_chart',
    'pass_rate_80': 'vivid_trophy',
    // AI連携バッジ
    'gemini_linked': 'vivid_tanuki',
  };

  String get _medalAsset {
    final name = _assetByBadgeId[badgeId] ?? 'light_seedling';
    return 'assets/badges/$name.png';
  }

  // 未獲得時のグレースケール変換用カラーマトリクス(輝度ベース)。
  // 専用のロック画像を用意する代わりに、各バッジ本来の絵柄をそのまま
  // グレー化+半透明にすることで「まだ獲得していない」ことを表す。
  static const List<double> _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final medalImage = Image.asset(
      _medalAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    return SizedBox(
      width: size,
      height: size,
      child: unlocked
          ? medalImage
          : Opacity(
              opacity: 0.5,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
                child: medalImage,
              ),
            ),
    );
  }
}

/// メダルの下に付く小さなリボン風タグ。バッジ名や「NEW」表示などに使う。
class BadgeRibbonTag extends StatelessWidget {
  final String text;
  final BadgeTier tier;
  final bool unlocked;

  const BadgeRibbonTag({
    super.key,
    required this.text,
    required this.tier,
    required this.unlocked,
  });

  Color get _color {
    if (!unlocked) return AppColors.textMute;
    switch (tier) {
      case BadgeTier.light:
        return const Color(0xFF2E7FE0);
      case BadgeTier.vivid:
        return AppColors.primary;
      case BadgeTier.silver:
        return const Color(0xFF6B7686);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: unlocked ? _color.withValues(alpha: 0.12) : AppColors.bgSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
