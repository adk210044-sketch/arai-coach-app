// bookmarked_questions_screen.dart — 保存(ブックマーク)した問題の一覧画面。
// 正解/不正解画面(explanation_screen.dart)で「📌 保存する」を押した問題を、
// アプリ内でいつでも見返せるようにするための画面。タップすると1問だけの
// 演習セッションとして問題画面(QuestionScreen)を開く。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../theme/app_colors_ext.dart';
import '../state/app_state.dart';
import '../models/question.dart';
import '../widgets/app_chip.dart';
import '../theme/category_colors.dart';
import 'question_screen.dart';

class BookmarkedQuestionsScreen extends StatelessWidget {
  const BookmarkedQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final questions = appState.bookmarkedQuestions;

    return Scaffold(
      backgroundColor: context.appColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: context.appColors.surfaceSoft,
        elevation: 0,
        title: Text(
          '保存した問題 (${questions.length})',
          style: TextStyle(
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w700,
            color: context.appColors.text,
          ),
        ),
      ),
      body: SafeArea(
        child: questions.isEmpty
            ? _emptyState(context)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _questionCard(context, appState, questions[index]),
              ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📌', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(
              'まだ保存した問題がないよ',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w700,
                color: context.appColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '正解・不正解の画面で「📌 保存する」を押すと、\nあとで見返したい問題をここにまとめておけるよ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.md,
                color: context.appColors.textDim,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(BuildContext context, AppState appState, Question q) {
    return GestureDetector(
      onTap: () {
        appState.startSingleQuestionSession(q);
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const QuestionScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppChip(
                  label: q.categoryName,
                  bg: CategoryColors.of(q.categoryKey).bg,
                  fg: CategoryColors.of(q.categoryKey).fg,
                ),
                const SizedBox(width: 6),
                AppChip(
                  label: q.format == QuestionFormat.ox ? '◯×問題' : '五肢択一',
                  bg: context.appColors.neutralSoft,
                  fg: context.appColors.neutralFg,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => appState.toggleBookmark(q.id),
                  child: const Icon(
                    Icons.bookmark,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              q.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppFontSize.md,
                height: 1.6,
                color: context.appColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${q.number} · ${q.year}',
                  style: TextStyle(
                    fontSize: AppFontSize.xs,
                    color: context.appColors.textMute,
                  ),
                ),
                const Spacer(),
                const Text(
                  'タップして解く →',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
