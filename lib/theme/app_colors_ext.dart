// app_colors_ext.dart — ダークモード対応のための「意味ベース」の色定義。
//
// tokens.dart の AppColors は元々ライトモード専用の固定色として設計されていた
// (bg/bgSoft/bgCard/text/textDim/textMute/border/borderSoft)。
// ダークモードに切り替えても画面が追従するように、ThemeExtension として
// ライト/ダークそれぞれの色セットを持たせ、`context.appColors.xxx` で
// 現在のテーマに応じた色を取得できるようにする。
//
// brand色(primary/accent/ok/ng/yellow/heat*)は明暗共通でそのまま使う
// (AppColors.primary等はこれまでと同様に直接参照してよい)。
import 'package:flutter/material.dart';
import 'tokens.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color surface; // 画面の背景色(旧 AppColors.bg)
  final Color surfaceSoft; // 画面の下地色(旧 AppColors.bgSoft)
  final Color card; // カード等の背景色(旧 AppColors.bgCard / Colors.white)
  final Color text; // 主要テキスト色(旧 AppColors.text)
  final Color textDim; // 中間テキスト色(旧 AppColors.textDim)
  final Color textMute; // 控えめテキスト色(旧 AppColors.textMute)
  final Color border; // 枠線色(旧 AppColors.border)
  final Color borderSoft; // 薄い枠線色(旧 AppColors.borderSoft)
  final Color neutralSoft; // ニュートラルチップ背景(旧 AppColors.neutralSoft)
  final Color neutralFg; // ニュートラルチップ文字(旧 AppColors.neutralFg)

  const AppSemanticColors({
    required this.surface,
    required this.surfaceSoft,
    required this.card,
    required this.text,
    required this.textDim,
    required this.textMute,
    required this.border,
    required this.borderSoft,
    required this.neutralSoft,
    required this.neutralFg,
  });

  static const light = AppSemanticColors(
    surface: AppColors.bg,
    surfaceSoft: AppColors.bgSoft,
    card: AppColors.bgCard,
    text: AppColors.text,
    textDim: AppColors.textDim,
    textMute: AppColors.textMute,
    border: AppColors.border,
    borderSoft: AppColors.borderSoft,
    neutralSoft: AppColors.neutralSoft,
    neutralFg: AppColors.neutralFg,
  );

  static const dark = AppSemanticColors(
    surface: Color(0xFF0B1220),
    surfaceSoft: Color(0xFF0B1220),
    card: Color(0xFF1A2333),
    text: Color(0xFFE5E7EB),
    textDim: Color(0xFFA0AEC0),
    textMute: Color(0xFF71809A),
    border: Color(0xFF2A3548),
    borderSoft: Color(0xFF1F2A3C),
    neutralSoft: Color(0xFF232E42),
    neutralFg: Color(0xFFB8C2D4),
  );

  @override
  AppSemanticColors copyWith({
    Color? surface,
    Color? surfaceSoft,
    Color? card,
    Color? text,
    Color? textDim,
    Color? textMute,
    Color? border,
    Color? borderSoft,
    Color? neutralSoft,
    Color? neutralFg,
  }) {
    return AppSemanticColors(
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      card: card ?? this.card,
      text: text ?? this.text,
      textDim: textDim ?? this.textDim,
      textMute: textMute ?? this.textMute,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      neutralSoft: neutralSoft ?? this.neutralSoft,
      neutralFg: neutralFg ?? this.neutralFg,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      card: Color.lerp(card, other.card, t)!,
      text: Color.lerp(text, other.text, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      textMute: Color.lerp(textMute, other.textMute, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      neutralSoft: Color.lerp(neutralSoft, other.neutralSoft, t)!,
      neutralFg: Color.lerp(neutralFg, other.neutralFg, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  /// 現在のテーマ(ライト/ダーク)に応じたセマンティックカラーを取得する。
  /// 例: `context.appColors.card` はライトモードでは白、ダークモードでは
  /// ダークグレーのカード背景色になる。
  AppSemanticColors get appColors {
    return Theme.of(this).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
  }
}
