// all_badges_screen.dart — 全実績バッジをカテゴリ別に一覧表示する画面。
// モチベーション向上・維持のため、初操作/継続学習/合格力/AI連携の4カテゴリで
// 現在の獲得状況を一目で確認できるようにする。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/badge.dart';
import '../widgets/badge_detail_dialog.dart';
import '../widgets/badge_medal.dart';
import '../widgets/coach_bubble.dart';

class AllBadgesScreen extends StatelessWidget {
  const AllBadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final grouped = appState.badgesByCategory;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        backgroundColor: AppColors.bgSoft,
        elevation: 0,
        title: Text(
          '実績バッジ一覧',
          style: TextStyle(
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CoachAvatar(size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${appState.unlockedBadgeCount} / ${appState.totalBadgeCount} 個獲得したよ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppFontSize.lg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'コツコツ続けて、まだ見ぬバッジも集めていこうね',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: AppFontSize.sm,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (final cat in BadgeCategory.values)
                _CategorySection(category: cat, badges: grouped[cat] ?? []),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final BadgeCategory category;
  final List<AppBadge> badges;

  const _CategorySection({required this.category, required this.badges});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = badges.where((b) => b.unlocked).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$unlockedCount/${badges.length}',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadow.card,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.64,
              ),
              itemCount: badges.length,
              itemBuilder: (context, i) {
                final b = badges[i];
                return GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => BadgeDetailDialog(badge: b),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: b.unlocked
                          ? AppColors.primaryFaint
                          : AppColors.bgSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BadgeMedal(
                          badgeId: b.id,
                          unlocked: b.unlocked,
                          size: 80,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          b.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: b.unlocked
                                ? AppColors.text
                                : AppColors.textMute,
                          ),
                        ),
                        if (!b.unlocked)
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              '未達成',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMute,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
