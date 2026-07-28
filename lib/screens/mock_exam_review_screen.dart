import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../models/question.dart';
import '../widgets/choice_item.dart';
import '../widgets/app_chip.dart';

/// 模擬試験終了後、問題ごとの正解/不正解と解説を確認できるレビュー画面。
/// mock_exam_result_screen.dart の「解答を確認する」から遷移する。
class MockExamReviewScreen extends StatefulWidget {
  final List<Question> questions;
  final List<int?> userAnswers;

  const MockExamReviewScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<MockExamReviewScreen> createState() => _MockExamReviewScreenState();
}

class _MockExamReviewScreenState extends State<MockExamReviewScreen> {
  // -1: すべて表示, 0: 不正解のみ, 1: 正解のみ
  int _filter = -1;

  bool _isCorrect(int i) =>
      widget.userAnswers[i] == widget.questions[i].correctIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final correctCount = List.generate(
      total,
      (i) => _isCorrect(i),
    ).where((v) => v).length;

    final visibleIndexes = List.generate(total, (i) => i).where((i) {
      if (_filter == -1) return true;
      if (_filter == 0) return !_isCorrect(i);
      return _isCorrect(i);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        backgroundColor: AppColors.bgSoft,
        title: const Text(
          '解答を確認',
          style: TextStyle(
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryBox('正解', '$correctCount問', AppColors.ok),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryBox(
                      '不正解',
                      '${total - correctCount}問',
                      AppColors.ng,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Row(
                children: [
                  _filterChip('すべて ($total)', -1),
                  const SizedBox(width: 8),
                  _filterChip('不正解のみ (${total - correctCount})', 0),
                  const SizedBox(width: 8),
                  _filterChip('正解のみ ($correctCount)', 1),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: visibleIndexes.isEmpty
                  ? const Center(
                      child: Text(
                        '該当する問題はありません',
                        style: TextStyle(color: AppColors.textDim),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      itemCount: visibleIndexes.length,
                      itemBuilder: (context, idx) {
                        final i = visibleIndexes[idx];
                        return _questionCard(i);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.card,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppFontSize.xxl,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSize.sm,
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.sm,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textDim,
          ),
        ),
      ),
    );
  }

  Widget _questionCard(int i) {
    final q = widget.questions[i];
    final userAnswer = widget.userAnswers[i];
    final correct = _isCorrect(i);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
        border: Border(
          left: BorderSide(
            color: correct ? AppColors.ok : AppColors.ng,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: correct
                      ? AppColors.ok.withValues(alpha: 0.15)
                      : AppColors.ng.withValues(alpha: 0.15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  correct ? Icons.check : Icons.close,
                  size: 16,
                  color: correct ? AppColors.ok : AppColors.ng,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '第${i + 1}問',
                style: const TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDim,
                ),
              ),
              const Spacer(),
              AppChip(label: q.categoryName),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.text,
            style: const TextStyle(
              fontSize: AppFontSize.md,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (q.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...q.items.map(
              (it) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  it,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textDim,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...List.generate(q.choices.length, (ci) {
            ChoiceState state;
            if (ci == q.correctIndex) {
              state = ChoiceState.correct;
            } else if (ci == userAnswer) {
              state = ChoiceState.incorrect;
            } else {
              state = ChoiceState.normal;
            }
            return ChoiceItem(label: q.choices[ci], state: state);
          }),
          if (userAnswer == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.bgSoft,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: const Text(
                '未回答でした',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      'あらいコーチの解説',
                      style: TextStyle(
                        fontSize: AppFontSize.sm,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  q.aiExplanation.isNotEmpty
                      ? q.aiExplanation
                      : q.officialExplanation,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    height: 1.7,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
