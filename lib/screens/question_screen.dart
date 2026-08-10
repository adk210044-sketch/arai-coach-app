import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/question.dart';
import '../widgets/app_chip.dart';
import '../widgets/choice_item.dart';
import '../theme/category_colors.dart';
import 'explanation_screen.dart';

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  // 演習を中断してTOPに戻る前に、誤タップによる中断を防ぐための確認ダイアログ。
  // ここで「中止する」を選んだ場合のみ、ルートスタックの先頭(TOP)まで一気に戻す。
  void _confirmQuit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('演習を中止しますか?'),
          content: Text(
            '今の演習を中止してTOPに戻るよ。ここまでの進行状況は保存されるので、次に同じメニューを選ぶと続きから再開できるよ。',
            style: TextStyle(color: AppColors.textDim, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('キャンセル', style: TextStyle(color: AppColors.textDim)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<AppState>().saveQuizProgress();
                if (context.mounted) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
              child: const Text(
                '中止する',
                style: TextStyle(
                  color: AppColors.ng,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.questionQueue.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = appState.currentQuestion;
    final progress =
        (appState.currentIndex + 1) / appState.questionQueue.length;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _confirmQuit(context),
                    icon: Icon(Icons.close, color: AppColors.textDim),
                  ),
                  if (appState.currentIndex > 0)
                    IconButton(
                      onPressed: () => appState.previousQuestion(),
                      icon: Icon(Icons.arrow_back, color: AppColors.textDim),
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
                    style: TextStyle(
                      fontSize: AppFontSize.base,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  AppChip(
                    label: q.format == QuestionFormat.ox ? '◯×問題' : '五肢択一',
                    bg: AppColors.neutralSoft,
                    fg: AppColors.neutralFg,
                  ),
                  const SizedBox(width: 6),
                  AppChip(
                    label: q.categoryName,
                    bg: CategoryColors.of(q.categoryKey).bg,
                    fg: CategoryColors.of(q.categoryKey).fg,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadow.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${q.number} · ${q.year}',
                              style: TextStyle(
                                fontSize: AppFontSize.xs,
                                color: AppColors.textDim,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q.text,
                              style: const TextStyle(
                                fontSize: AppFontSize.xxl,
                                height: 1.85,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (q.items.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...q.items.map(
                                (it) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    it,
                                    style: TextStyle(
                                      fontSize: AppFontSize.md,
                                      height: 1.6,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ...List.generate(q.choices.length, (i) {
                        ChoiceState state = ChoiceState.normal;
                        if (appState.answered) {
                          if (i == q.correctIndex) {
                            state = ChoiceState.correct;
                          } else if (i == appState.selectedAnswer) {
                            state = ChoiceState.incorrect;
                          }
                        } else if (appState.selectedAnswer == i) {
                          state = ChoiceState.selected;
                        }
                        return ChoiceItem(
                          label: q.displayChoices[i],
                          state: state,
                          onTap: appState.answered
                              ? null
                              : () => appState.selectAnswer(i),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: appState.answered
                          ? null
                          : () {
                              if (appState.hasNextQuestion) {
                                appState.nextQuestion();
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDim,
                        side: BorderSide(color: AppColors.border, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: const Text('スキップ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          appState.selectedAnswer == null || appState.answered
                          ? null
                          : () {
                              appState.submitAnswer();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ExplanationScreen(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.border,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: const Text(
                        '回答する',
                        style: TextStyle(
                          fontSize: AppFontSize.xl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
