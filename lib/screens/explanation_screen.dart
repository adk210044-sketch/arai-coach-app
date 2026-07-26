import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/question.dart';
import '../data/reference_tables.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/reference_table_card.dart';
import '../widgets/choice_item.dart';
import '../widgets/app_chip.dart';
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
                    const SizedBox(height: 10),
                    // 誤り報告(解説の正確性を担保する仕組み)
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 13,
                          color: AppColors.textMute,
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'AIコーチによる解説',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMute,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: appState.isExplanationReported(q.id)
                              ? null
                              : () => _reportIssue(context, appState, q),
                          child: Text(
                            appState.isExplanationReported(q.id)
                                ? '✅ 報告済み'
                                : '⚠️ 解説に誤りを見つけた',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: appState.isExplanationReported(q.id)
                                  ? AppColors.ok
                                  : AppColors.ng,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: _smallBtn(
                        '📄 問題文を見直す',
                        onTap: () => _showQuestionReview(context, appState, q),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            appState.isBookmarked(q.id) ? '📌 保存済み' : '📌 保存する',
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

              // 法令の数値比較表など、関連する図解データがあれば表示する
              ..._buildReferenceTables(q),

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

  List<Widget> _buildReferenceTables(Question q) {
    final combined =
        '${q.text} ${q.aiExplanation} ${q.officialExplanation} ${q.choices.join(' ')}';
    final tables = findReferenceTables(combined);
    if (tables.isEmpty) return const [];
    return [
      for (final t in tables) ...[
        ReferenceTableCard(table: t),
        const SizedBox(height: 14),
      ],
    ];
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

  /// 「問題文を見直す」ボトムシート。解答直後の画面は解説中心で
  /// 問題文が流れて見えなくなっているため、いつでも元の問題文・選択肢
  /// (自分の回答・正解がどれだったか付き)を見返せるようにする。
  void _showQuestionReview(
    BuildContext context,
    AppState appState,
    Question q,
  ) {
    final myAnswer = appState.selectedAnswer;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '📄 問題を見直す',
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
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppChip(
                                label: q.format == QuestionFormat.ox
                                    ? '◯×問題'
                                    : '五肢択一',
                                bg: AppColors.primarySoft,
                                fg: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              AppChip(
                                label: q.categoryName,
                                bg: const Color(0xFFFEF3C7),
                                fg: const Color(0xFFA16207),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${q.number} · ${q.year}',
                            style: const TextStyle(
                              fontSize: AppFontSize.xs,
                              color: AppColors.textDim,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            q.text,
                            style: const TextStyle(
                              fontSize: AppFontSize.xl,
                              height: 1.85,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                          ),
                          if (q.items.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...q.items.map(
                              (it) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  it,
                                  style: const TextStyle(
                                    fontSize: AppFontSize.md,
                                    height: 1.6,
                                    color: AppColors.textDim,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ...List.generate(q.choices.length, (i) {
                            ChoiceState state = ChoiceState.normal;
                            if (i == q.correctIndex) {
                              state = ChoiceState.correct;
                            } else if (i == myAnswer) {
                              state = ChoiceState.incorrect;
                            }
                            return ChoiceItem(label: q.choices[i], state: state);
                          }),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 13,
                                color: AppColors.textMute,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  myAnswer == null
                                      ? '緑枠が正解だよ'
                                      : '緑枠が正解、赤枠が自分の回答だよ',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textMute,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  void _reportIssue(BuildContext context, AppState appState, Question q) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ 解説に誤りを報告する',
                  style: TextStyle(
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '報告してくれると、運営チームが内容を確認して解説をすぐに修正するよ。ありがとう!',
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    color: AppColors.textDim,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      appState.reportExplanationIssue(q.id);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 2),
                          content: Text('報告を受け付けたよ。確認して修正するね'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: const Text(
                      'この解説を報告する',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
