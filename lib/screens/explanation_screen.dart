import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/question.dart';
import '../widgets/coach_bubble.dart';
import 'question_screen.dart';

class ExplanationScreen extends StatefulWidget {
  const ExplanationScreen({super.key});

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final q = appState.currentQuestion;
    final correct = appState.lastAnswerCorrect;
    final progress =
        (appState.currentIndex + 1) / appState.questionQueue.length;

    final bannerColors = correct
        ? const [Color(0xFFDCFCE7), Color(0xFFBBF7D0)]
        : const [Color(0xFFFEE2E2), Color(0xFFFECACA)];
    final bannerFg = correct
        ? const Color(0xFF166534)
        : const Color(0xFF991B1B);
    final circleColor = correct ? AppColors.ok : AppColors.ng;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.close, color: AppColors.textDim),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${appState.currentIndex + 1}/${appState.questionQueue.length}',
                    style: const TextStyle(
                      fontSize: AppFontSize.base,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              SlideTransition(
                position: _slide,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: bannerColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: circleColor.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          correct ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        correct ? '正解!' : '不正解',
                        style: TextStyle(
                          fontSize: AppFontSize.xxxxl,
                          fontWeight: FontWeight.w700,
                          color: bannerFg,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.resultComment,
                        style: TextStyle(
                          fontSize: AppFontSize.base,
                          color: bannerFg.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // AIコーチの解説
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadow.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CoachBubble(
                      title: 'あらいコーチ',
                      message: '',
                      mood: correct ? CoachMood.correct : CoachMood.incorrect,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.aiExplanation,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.9,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _smallBtn(
                            '💡 もっと詳しく',
                            onTap: () => _showFullExplanation(context, q),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _smallBtn(
                            appState.isBookmarked(q.id)
                                ? '📌 保存済み'
                                : '📌 保存する',
                            active: appState.isBookmarked(q.id),
                            onTap: () {
                              appState.toggleBookmark(q.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(seconds: 1),
                                  content: Text(
                                    appState.isBookmarked(q.id)
                                        ? 'マイページの保存リストに追加したよ'
                                        : '保存を解除したよ',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryFaint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'この解説はどうだった?',
                      style: TextStyle(
                        fontSize: AppFontSize.base,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['🎯 わかりやすい', '😅 まだ難しい', '🤔 別の説明で'].map((x) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _feedbackChip(
                              x,
                              onTap: () => _handleFeedback(context, q, x),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (appState.hasNextQuestion) {
                      appState.nextQuestion();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const QuestionScreen(),
                        ),
                      );
                    } else {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    appState.hasNextQuestion ? '次の問題へ →' : '結果を見る',
                    style: const TextStyle(
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallBtn(String label, {VoidCallback? onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryFaint : null,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.primary : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _feedbackChip(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSize.sm,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showFullExplanation(BuildContext context, Question q) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final official = q.officialExplanation.trim();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '📖 公式解説',
                      style: TextStyle(
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      official.isNotEmpty ? official : 'この問題には公式解説の全文がありません。',
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.9,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleFeedback(BuildContext context, Question q, String label) {
    String message;
    if (label.contains('わかりやすい')) {
      message = '嬉しいな、フィードバックありがとう!';
    } else if (label.contains('難しい')) {
      message = '教えてくれてありがとう。「もっと詳しく」で公式解説も見てみてね';
    } else {
      message = 'なるほど、別の説明パターンを検討するよ。フィードバックを記録したよ';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(duration: const Duration(seconds: 2), content: Text(message)),
    );
  }
}
