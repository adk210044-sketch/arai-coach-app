// badge_medal.dart — 実績バッジを「メダル」らしい質感で表示するウィジェット。
// CSSグラデーションでは金属質感を再現できなかったため、AI生成した
// 実写風メダル画像(assets/badges/)を土台に、その上へ絵文字アイコンを
// 重ねる方式で実装している。
// 金銀銅ではなく、本アプリのトンマナ(スタサプ的ブルー)に合わせて
// ライトブルー/ビビッドブルー/シルバーの3ティアでランクを表現する。
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../models/badge.dart';

class BadgeMedal extends StatelessWidget {
  final String icon;
  final BadgeTier tier;
  final bool unlocked;
  final double size;

  const BadgeMedal({
    super.key,
    required this.icon,
    required this.tier,
    required this.unlocked,
    this.size = 56,
  });

  // ティアごとの土台メダル画像パス。
  String get _medalAsset {
    if (!unlocked) return 'assets/badges/medal_locked.png';
    switch (tier) {
      case BadgeTier.light:
        return 'assets/badges/medal_light.png';
      case BadgeTier.vivid:
        return 'assets/badges/medal_vivid.png';
      case BadgeTier.silver:
        return 'assets/badges/medal_silver.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 土台メダル画像(AI生成の金属質感画像)
          Image.asset(
            _medalAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          // 中央の刻印プレートに絵文字アイコンを重ねる
          // (ロック済みメダルは画像自体に鍵アイコンが刻印済みのため不要)
          if (unlocked)
            Text(icon, style: TextStyle(fontSize: size * 0.30)),
        ],
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
