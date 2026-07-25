import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/question.dart';
import '../widgets/choice_item.dart';
import 'mock_exam_result_screen.dart';

class MockExamSessionScreen extends StatefulWidget {
  final int questionCount;
  final int durationSec;

  const MockExamSessionScreen({
    super.key,
    required this.questionCount,
    required this.durationSec,
  });

  @override
  State<MockExamSessionScreen> createState() => _MockExamSessionScreenState();
}

class _MockExamSessionScreenState extends State<MockExamSessionScreen> {
  late List<Question> _questions;
  late List<int?> _answers;
  int _currentIndex = 0;
  late int _remainingSec;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final basePool = context.read<AppState>().questionPool;
    final pool = List<Question>.from(basePool)..shuffle(Random());
    _questions = pool.take(widget.questionCount).toList();
    _answers = List<int?>.filled(_questions.length, null);
    _remainingSec = widget.durationSec;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _remainingSec--;
        if (_remainingSec <= 0) {
          _timer?.cancel();
          _submit();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final m = (_remainingSec ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isUrgent => _remainingSec <= 60;
  bool get _isWarning => _remainingSec <= 600 && _remainingSec > 60;

  void _submit() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correctIndex) score++;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MockExamResultScreen(
          score: score,
          total: _questions.length,
          passingScore: (_questions.length * 0.7).ceil(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: Column(
          children: [
            // Timer header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              color: _isUrgent
                  ? AppColors.ng.withValues(alpha: 0.1)
                  : Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _confirmExit(),
                    icon: const Icon(Icons.close, color: AppColors.textDim),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: _isUrgent ? AppColors.ng : AppColors.textDim,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _timeLabel,
                    style: TextStyle(
                      fontSize: AppFontSize.xxxl,
                      fontWeight: FontWeight.w700,
                      color: _isUrgent
                          ? AppColors.ng
                          : (_isWarning ? AppColors.accent : AppColors.text),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _submit,
                    child: const Text(
                      '提出する',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          Text(
                            '${q.number} · ${q.year}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textDim,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            q.text,
                            style: const TextStyle(
                              fontSize: AppFontSize.xxl,
                              height: 1.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (q.items.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ...q.items.map(
                              (it) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text(
                                  it,
                                  style: const TextStyle(
                                    fontSize: AppFontSize.md,
                                    color: AppColors.textDim,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(q.choices.length, (i) {
                      final selected = _answers[_currentIndex] == i;
                      return ChoiceItem(
                        label: q.choices[i],
                        state: selected
                            ? ChoiceState.selected
                            : ChoiceState.normal,
                        onTap: () =>
                            setState(() => _answers[_currentIndex] = i),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Question navigator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _questions.length,
                  itemBuilder: (context, i) {
                    final answered = _answers[i] != null;
                    final active = i == _currentIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = i),
                      child: Container(
                        width: 38,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : (answered
                                    ? AppColors.primarySoft
                                    : AppColors.bgSoft),
                          borderRadius: BorderRadius.circular(10),
                          border: active
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : (answered
                                      ? AppColors.primary
                                      : AppColors.textDim),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('模試を中断しますか?'),
        content: const Text('進行状況は保存され、後で再開できます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('中断する', style: TextStyle(color: AppColors.ng)),
          ),
        ],
      ),
    );
  }
}
