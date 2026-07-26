import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../widgets/ad_banner_placeholder.dart';
import 'question_screen.dart';
import 'mock_exam_screen.dart';
import 'calendar_screen.dart';
import 'paywall_screen.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final categories = appState.categoryStats;
    final isPremium = appState.canUseMockExam;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '演習 📖',
                  style: TextStyle(
                    fontSize: AppFontSize.xxxxl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadow.card,
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPremium
                  ? 'カテゴリを選んで演習を始めよう'
                  : 'カテゴリを選んで演習を始めよう(フリープランは過去問50問まで)',
              style: const TextStyle(
                fontSize: AppFontSize.base,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 14),
            const AdBannerPlaceholder(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shuffle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ランダム10問',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<AppState>().startSession(count: 10);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const QuestionScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: const Text(
                      '始める',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'カテゴリ別演習',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...categories.map((cat) {
              final pct = cat.accuracyPercent;
              final barColor = pct < 60
                  ? AppColors.ng
                  : (pct < 75 ? AppColors.yellow : AppColors.ok);
              return GestureDetector(
                onTap: () {
                  context.read<AppState>().startSession(
                    categoryKey: cat.key,
                    count: 10,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuestionScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadow.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                cat.name,
                                style: const TextStyle(
                                  fontSize: AppFontSize.md,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (cat.weak) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: const Text(
                                    '要復習',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.ng,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textMute),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 6,
                                backgroundColor: AppColors.borderSoft,
                                valueColor: AlwaysStoppedAnimation(barColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: AppFontSize.base,
                              fontWeight: FontWeight.w700,
                              color: barColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                if (!isPremium) {
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
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadow.card,
                ),
                child: Row(
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '模擬試験',
                            style: TextStyle(
                              fontSize: AppFontSize.md,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPremium ? '本番形式で実力チェック' : '🔒 プレミアム限定の機能だよ',
                            style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: isPremium
                                  ? AppColors.textDim
                                  : AppColors.accent,
                              fontWeight: isPremium
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isPremium ? Icons.chevron_right : Icons.lock_outline,
                      color: isPremium ? AppColors.textMute : AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
