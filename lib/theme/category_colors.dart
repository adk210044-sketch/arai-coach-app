// category_colors.dart — カテゴリ(categoryKey)ごとの表示色を一元管理する。
// 問題画面・解説画面・ブックマーク・模試レビューなど、カテゴリチップを表示する
// すべての画面はここ経由で色を取得することで、アプリ全体で配色を統一する。
import 'package:flutter/material.dart';

class CategoryColor {
  final Color bg;
  final Color fg;
  const CategoryColor(this.bg, this.fg);
}

class CategoryColors {
  CategoryColors._();

  static const Map<String, CategoryColor> _map = {
    // 関係法令(有害以外) — 青系(アプリの基調色に寄せた落ち着いた青)
    'law_general': CategoryColor(Color(0xFFDCEBFF), Color(0xFF1D4ED8)),
    // 関係法令(有害) — 紫系(法令の中でも「有害業務」を区別)
    'law_harm': CategoryColor(Color(0xFFEDE4FF), Color(0xFF6D28D9)),
    // 労働衛生(有害以外) — 緑系
    'labor_general': CategoryColor(Color(0xFFDCFCE7), Color(0xFF15803D)),
    // 労働衛生(有害) — オレンジ系(注意喚起の色味で「有害」を強調)
    'labor_harm': CategoryColor(Color(0xFFFFE4D6), Color(0xFFC2410C)),
    // 労働生理 — 黄系
    'physiology': CategoryColor(Color(0xFFFEF3C7), Color(0xFFA16207)),
  };

  static const CategoryColor _fallback = CategoryColor(
    Color(0xFFEEF2F7),
    Color(0xFF64748B),
  );

  static CategoryColor of(String categoryKey) => _map[categoryKey] ?? _fallback;
}
