// badge_medal.dart — 実績バッジを「メダル」らしい質感で表示するウィジェット。
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

  // ティアごとのグラデーション(明るい面 → 濃い面)とリム(縁取り)色。
  List<Color> get _gradientColors {
    switch (tier) {
      case BadgeTier.light:
        return const [Color(0xFF9FCBFF), Color(0xFF4B9EFF), Color(0xFF2E7FE0)];
      case BadgeTier.vivid:
        return const [Color(0xFF4B9EFF), Color(0xFF0369E5), Color(0xFF00489C)];
      case BadgeTier.silver:
        return const [Color(0xFFF3F6FA), Color(0xFFC3CDD9), Color(0xFF8C99A8)];
    }
  }

  Color get _rimColor {
    switch (tier) {
      case BadgeTier.light:
        return const Color(0xFF1E63B8);
      case BadgeTier.vivid:
        return const Color(0xFF00337A);
      case BadgeTier.silver:
        return const Color(0xFF6B7686);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return _buildLocked();
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 影(下方向に柔らかく落とす)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _rimColor.withValues(alpha: 0.35),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            ),
          ),
          // 本体(金属グラデーション)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradientColors,
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(color: _rimColor, width: size * 0.035),
            ),
          ),
          // 光沢(左上のハイライト)
          Positioned(
            top: size * 0.10,
            left: size * 0.14,
            child: Container(
              width: size * 0.42,
              height: size * 0.30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.3),
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // 中央の刻印プレート + アイコン
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.92),
              boxShadow: [
                BoxShadow(
                  color: _rimColor.withValues(alpha: 0.25),
                  blurRadius: size * 0.05,
                  offset: Offset(0, size * 0.015),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(icon, style: TextStyle(fontSize: size * 0.30)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocked() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgSoft,
        border: Border.all(
          color: AppColors.border,
          width: size * 0.03,
          style: BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.lock_outline,
        size: size * 0.34,
        color: AppColors.textMute,
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
