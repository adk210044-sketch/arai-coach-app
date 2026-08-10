// quiz_resume_dialog.dart — 通常演習(今日のタスク・カテゴリ別・ランダム等)の
// 開始時に、前回中断した演習が残っている場合「続きから/最初から」を選べる
// 共通ダイアログ。演習を開始するすべての入り口(ホーム/演習/分析画面)から
// このヘルパーを経由することで、挙動を統一する。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../screens/question_screen.dart';

/// 演習を開始する共通処理。
/// 保存済みの中断セッションがなければ即座に [onStartNew] を呼んで新規セッションを
/// 開始する。保存済みセッションがある場合は確認ダイアログを表示し、
/// 「続きから」なら保存内容を復元、「最初から」なら [onStartNew] で新規開始する。
void startQuizSession(
  BuildContext context, {
  required VoidCallback onStartNew,
}) {
  final appState = context.read<AppState>();

  void pushQuestionScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QuestionScreen()));
  }

  if (!appState.hasSavedQuizProgress) {
    onStartNew();
    pushQuestionScreen();
    return;
  }

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('前回の続きがあるよ'),
        content: Text(
          '前回中断した演習が残っているよ。続きから再開する?\n'
          '「最初から」を選ぶと、前回の進行状況は削除されるよ。',
          style: TextStyle(color: AppColors.textDim, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await appState.clearQuizProgress();
              onStartNew();
              pushQuestionScreen();
            },
            child: Text('最初から', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final resumed = appState.resumeQuizProgress();
              if (!resumed) {
                // 復元に失敗した場合(問題データ不整合など)は新規開始にフォールバック。
                onStartNew();
              }
              pushQuestionScreen();
            },
            child: const Text(
              '続きから',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
}
