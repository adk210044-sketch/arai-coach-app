import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_colors_ext.dart';

/// あらいコーチの表情バリエーション
enum CoachMood {
  /// 通常時(ホーム画面・コーチ画面など)
  normal,

  /// 正解した時(両手を上げて花丸で喜ぶ)
  correct,

  /// 不正解の時(優しく励ますハート付き)
  incorrect,

  /// やる気を出す時(ガッツポーズ)
  motivate,

  /// 満点・達成した時(トロフィーでお祝い)
  perfect,
}

extension CoachMoodAsset on CoachMood {
  String get assetPath {
    switch (this) {
      case CoachMood.normal:
        return 'assets/characters/arai_coach.png';
      case CoachMood.correct:
        return 'assets/characters/arai_coach_correct.png';
      case CoachMood.incorrect:
        return 'assets/characters/arai_coach_incorrect.png';
      case CoachMood.motivate:
        return 'assets/characters/arai_coach_motivate.png';
      case CoachMood.perfect:
        return 'assets/characters/arai_coach_perfect.png';
    }
  }
}

/// あらいコーチ(アライグマのマスコット)の吹き出し
class CoachAvatar extends StatelessWidget {
  final double size;
  final CoachMood mood;
  const CoachAvatar({super.key, this.size = 56, this.mood = CoachMood.normal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight.withValues(alpha: 0.25),
        border: Border.all(color: Colors.white, width: size * 0.045),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(
        child: Image.asset(
          mood.assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'あ',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CoachBubble extends StatelessWidget {
  final String title;
  final String message;
  final Widget? trailing;
  final CoachMood mood;

  const CoachBubble({
    super.key,
    this.title = 'あらいコーチより',
    required this.message,
    this.trailing,
    this.mood = CoachMood.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoachAvatar(mood: mood),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.7,
                  color: context.appColors.text,
                ),
              ),
              if (trailing != null) ...[const SizedBox(height: 8), trailing!],
            ],
          ),
        ),
      ],
    );
  }
}
