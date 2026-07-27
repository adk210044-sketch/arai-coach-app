// badge_detail_dialog.dart — バッジ詳細/獲得お祝いダイアログ。
// タップ時の詳細表示と、新規獲得時のお祝い表示の両方をこの1つのウィジェットで担う。
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../models/badge.dart';
import 'badge_medal.dart';

class BadgeDetailDialog extends StatelessWidget {
  final AppBadge badge;

  /// trueの場合、「新しく獲得したよ!」というお祝い演出で表示する。
  final bool isCelebration;

  const BadgeDetailDialog({
    super.key,
    required this.badge,
    this.isCelebration = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadow.cardHover,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCelebration) ...[
              const Text(
                '🎉 バッジ獲得!',
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
            ],
            BadgeMedal(
              badgeId: badge.id,
              unlocked: badge.unlocked,
              size: 92,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${badge.category.emoji} ${badge.category.label}',
                    style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                BadgeRibbonTag(
                  text: _tierLabel(badge.tier),
                  tier: badge.tier,
                  unlocked: badge.unlocked,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.base,
                color: AppColors.textDim,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            if (!badge.unlocked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: AppColors.textMute,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '未獲得だよ、これから挑戦してみよう',
                      style: TextStyle(
                        fontSize: AppFontSize.sm,
                        color: AppColors.textMute,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: Text(
                  isCelebration ? 'おめでとう!' : '閉じる',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tierLabel(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.light:
        return 'ライトブルー';
      case BadgeTier.vivid:
        return 'ビビッドブルー';
      case BadgeTier.silver:
        return 'シルバー';
    }
  }
}
