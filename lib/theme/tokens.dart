// tokens.dart — B案(親しみブルー・スタサプ的)のデザイントークン
// 出典: design_handoff_hygiene_manager_app/IMPLEMENTATION_SPEC.md セクション4
// 色は必ずここ経由で参照。ハードコード禁止。

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bg = Color(0xFFFFFFFF);
  static const Color bgSoft = Color(0xFFF4F7FB);
  static const Color bgCard = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFF0369E5);
  static const Color primaryDark = Color(0xFF0057C2);
  static const Color primarySoft = Color(0xFFE4F0FF);
  static const Color primaryFaint = Color(0xFFF0F7FF);
  static const Color primaryLight = Color(0xFF4B9EFF);

  static const Color accent = Color(0xFFFF7A45);
  static const Color yellow = Color(0xFFFFC542);

  static const Color ok = Color(0xFF22C55E);
  static const Color ng = Color(0xFFEF4444);

  static const Color text = Color(0xFF0F172A);
  static const Color textDim = Color(0xFF64748B);
  static const Color textMute = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSoft = Color(0xFFEEF2F7);

  // 出題形式チップ(「五肢択一」「◯×問題」)用のニュートラルなグレー。
  // カテゴリチップと視覚的に区別するため、あえて彩度を持たせない。
  static const Color neutralSoft = Color(0xFFEDEFF3);
  static const Color neutralFg = Color(0xFF475569);

  // Heatmap / streak color scale
  static const Color heat0 = bgSoft;
  static const Color heat1 = Color(0xFFDBEAFE);
  static const Color heat2 = Color(0xFF93C5FD);
  static const Color heat3 = primary;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

class AppRadius {
  AppRadius._();
  static const double chip = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double pill = 999;
}

class AppShadow {
  AppShadow._();
  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.text.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> cardHover = [
    BoxShadow(
      color: AppColors.text.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppFontSize {
  AppFontSize._();
  static const double xs = 10;
  static const double sm = 11;
  static const double base = 12;
  static const double md = 13;
  static const double lg = 14;
  static const double xl = 15;
  static const double xxl = 17;
  static const double xxxl = 20;
  static const double xxxxl = 24;
  static const double xxxxxl = 28;
  static const double xxxxxxl = 34;
}
