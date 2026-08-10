import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../theme/app_colors_ext.dart';
import '../state/app_state.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/pass_probability_card.dart';
import '../widgets/ad_banner_placeholder.dart';
import '../widgets/intensive_pack_promo_card.dart';
import '../widgets/quiz_resume_dialog.dart';
import 'mock_exam_screen.dart';
import 'paywall_screen.dart';
import 'bookmarked_questions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final daysLeft = profile.daysUntilExam;
    final plan = appState.dailyPlan;
    final goalTotal = appState.dailyGoal;
    final goalDone = appState.todayAnswered.clamp(0, goalTotal);
    final goalPct = goalTotal == 0 ? 0.0 : goalDone / goalTotal;
    final passProbability = appState.passProbability;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'おかえりなさい 👋',
                      style: TextStyle(
                        fontSize: AppFontSize.xxxxl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '今日もコツコツやっていこう',
                      style: TextStyle(
                        fontSize: AppFontSize.md,
                        color: context.appColors.textDim,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName.substring(0, 1)
                        : '康',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const IntensivePackPromoCard(),
            const AdBannerPlaceholder(),
            const SizedBox(height: 4),

            // AIコーチのメッセージ
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadow.card,
              ),
              child: CoachBubble(
                mood: CoachMood.motivate,
                message: appState.profile.totalAnswered > 0
                    ? '昨日もお疲れさまだよ。\n今日は「${plan.categoryName}」を重点的に一緒に取り組んでみようね。'
                    : '初めまして、あらいコーチだよ!\n今日は「${plan.categoryName}」から一緒に取り組んでみようね。',
              ),
            ),
            const SizedBox(height: 14),

            // 合格可能性
            PassProbabilityCard(result: passProbability),
            const SizedBox(height: 14),

            // 今日のゴール
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            daysLeft != null
                                ? '試験まで$daysLeft日 · 今日のタスク'
                                : '今日のタスク',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppFontSize.base,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$goalDone',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / $goalTotal問',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          goalDone >= goalTotal
                              ? '達成!'
                              : 'あと${goalTotal - goalDone}問',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppFontSize.sm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📌 全分野から${plan.targetCount}問(${plan.categoryName}を重点強化)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: AppFontSize.sm,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: goalPct.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        startQuizSession(
                          context,
                          onStartNew: () => context
                              .read<AppState>()
                              .startDailyTaskSession(plan.categoryDistribution),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 18),
                          SizedBox(width: 6),
                          Text(
                            '今日のタスクを始める',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Streak + Days
            Row(
              children: [
                Expanded(
                  flex: 13,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppShadow.card,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEE4),
                            borderRadius: BorderRadius.circular(23),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.local_fire_department,
                            color: AppColors.accent,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${profile.streakDays}',
                                    style: TextStyle(
                                      color: context.appColors.text,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '日連続',
                                    style: TextStyle(
                                      color: context.appColors.textDim,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '最長 ${profile.longestStreak}日',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.appColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 10,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppShadow.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '試験まで',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.appColors.textDim,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: daysLeft != null ? '$daysLeft' : '--',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: '日',
                                style: TextStyle(
                                  color: context.appColors.textDim,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _bookmarkButton(context, appState),
            const SizedBox(height: 20),

            const Text(
              'おすすめメニュー',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _menuTile(
              context,
              appState.isPremium ? '🧠' : '📖',
              appState.isPremium ? '苦手復習(AI優先)' : '苦手復習(シンプル版)',
              appState.isPremium
                  ? '${appState.weakReviewCategoryName ?? "AI分析中"} · AIが優先順に出題'
                  : '${appState.weakReviewCategoryName ?? "関係法令"} · 10問',
              appState.isPremium
                  ? AppColors.primaryFaint
                  : const Color(0xFFFFEEE4),
              onTap: () {
                startQuizSession(
                  context,
                  onStartNew: () => context
                      .read<AppState>()
                      .startWeakReviewSession(count: 10),
                );
              },
            ),
            _menuTile(
              context,
              '⚡',
              'スキマ学習',
              '5分でサッと3問',
              const Color(0xFFFFF7DC),
              onTap: () {
                startQuizSession(
                  context,
                  onStartNew: () => context.read<AppState>().startSession(
                    count: 3,
                    isGapStudy: true,
                  ),
                );
              },
            ),
            _menuTile(
              context,
              '📝',
              '模擬試験',
              appState.canUseMockExam ? '44問 / 本番形式' : '🔒 プレミアム限定',
              AppColors.primaryFaint,
              locked: !appState.canUseMockExam,
              onTap: () {
                if (!appState.canUseMockExam) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const PaywallScreen(trigger: PaywallTrigger.mockExam),
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MockExamScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookmarkButton(BuildContext context, AppState appState) {
    final count = appState.bookmarkedIds.length;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BookmarkedQuestionsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('📌', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '保存した問題 ($count件)',
                    style: const TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '見返したい問題をあとでまとめて復習できるよ',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: context.appColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.appColors.textMute,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    String emoji,
    String title,
    String sub,
    Color bg, {
    VoidCallback? onTap,
    bool locked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: locked
                          ? AppColors.accent
                          : context.appColors.textDim,
                      fontWeight: locked ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              locked ? Icons.lock_outline : Icons.chevron_right,
              color: locked ? AppColors.accent : context.appColors.textMute,
              size: locked ? 18 : 24,
            ),
          ],
        ),
      ),
    );
  }
}
