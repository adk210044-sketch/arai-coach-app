import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/coach_bubble.dart';

class MockExamResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final int passingScore;

  const MockExamResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.passingScore,
  });

  @override
  Widget build(BuildContext context) {
    final passed = score >= passingScore;
    final isPerfect = total > 0 && score == total;
    final pct = total == 0 ? 0 : (score / total * 100).round();
    final mood = isPerfect
        ? CoachMood.perfect
        : (passed ? CoachMood.correct : CoachMood.incorrect);

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passed
                      ? AppColors.ok.withValues(alpha: 0.12)
                      : AppColors.ng.withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: CoachAvatar(size: 112, mood: mood),
              ),
              const SizedBox(height: 20),
              Text(
                passed ? '合格ライン達成!' : 'もう少し頑張ろう',
                style: const TextStyle(
                  fontSize: AppFontSize.xxxxl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$score / $total問正解 ($pct%)',
                style: const TextStyle(
                  fontSize: AppFontSize.lg,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadow.card,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '合格ライン',
                          style: TextStyle(color: AppColors.textDim),
                        ),
                        Text(
                          '$passingScore問 以上',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'あなたの得点',
                          style: TextStyle(color: AppColors.textDim),
                        ),
                        Text(
                          '$score問',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: passed ? AppColors.ok : AppColors.ng,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'ホームに戻る',
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
