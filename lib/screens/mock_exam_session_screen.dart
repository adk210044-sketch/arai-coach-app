import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/question.dart';
import '../data/question_repository.dart';
import '../widgets/choice_item.dart';
import 'mock_exam_result_screen.dart';

class MockExamSessionScreen extends StatefulWidget {
  final int questionCount;
  final int durationSec;

  /// true: ミニ模試(10問) / false: フル模擬試験。
  /// 一時保存・受験履歴をフル/ミニで区別するために使う。
  final bool isMini;

  /// 一時保存データから再開する場合に渡す(nullなら新規開始)。
  final Map<String, dynamic>? resumeData;

  const MockExamSessionScreen({
    super.key,
    required this.questionCount,
    required this.durationSec,
    required this.isMini,
    this.resumeData,
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
  Timer? _autoSaveDebounce;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final resume = widget.resumeData;
    if (resume != null) {
      // 一時保存データから復元(保存時と同じ問題順・回答状況・残り時間)
      final repo = QuestionRepository.instance;
      final ids = List<String>.from(resume['questionIds'] as List);
      final byId = {for (final q in repo.all) q.id: q};
      _questions = ids.map((id) => byId[id]).whereType<Question>().toList();
      final savedAnswers = (resume['answers'] as List)
          .map((e) => e as int?)
          .toList();
      // 復元後の問題数が保存時と食い違う(データ更新等)場合に備えて長さを揃える
      _answers = List<int?>.generate(
        _questions.length,
        (i) => i < savedAnswers.length ? savedAnswers[i] : null,
      );
      final savedIndex = resume['currentIndex'] as int? ?? 0;
      _currentIndex = savedIndex < _questions.length ? savedIndex : 0;
      _remainingSec = (resume['remainingSec'] as int?) ?? widget.durationSec;
      if (_questions.isEmpty) {
        // 復元に失敗した場合は新規開始にフォールバック
        _startFresh();
      }
    } else {
      _startFresh();
    }
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

  void _startFresh() {
    final basePool = context.read<AppState>().questionPool;
    final pool = List<Question>.from(basePool)..shuffle(Random());
    _questions = pool.take(widget.questionCount).toList();
    _answers = List<int?>.filled(_questions.length, null);
    _currentIndex = 0;
    _remainingSec = widget.durationSec;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveDebounce?.cancel();
    super.dispose();
  }

  /// 進行状況を保存する。[showFeedback]がtrueならSnackBarで完了を知らせる。
  Future<void> _saveProgress({bool showFeedback = false}) async {
    final appState = context.read<AppState>();
    await appState.saveMockExamProgress(
      questionIds: _questions.map((q) => q.id).toList(),
      answers: _answers,
      currentIndex: _currentIndex,
      remainingSec: _remainingSec,
      questionCount: widget.questionCount,
      durationSec: widget.durationSec,
      isMini: widget.isMini,
    );
    if (!mounted) return;
    if (showFeedback) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('一時保存しました。ホーム画面からいつでも再開できます。'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 回答を選択した際、少し間を置いてから自動保存する(タップごとの負荷を抑えるためデバウンス)。
  void _scheduleAutoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 400), () {
      _saveProgress();
    });
  }

  Future<void> _manualSave() async {
    setState(() => _isSaving = true);
    await _saveProgress(showFeedback: true);
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
      final ans = _answers[i];
      if (ans != null && _questions[i].isCorrectAnswer(ans)) score++;
    }
    final appState = context.read<AppState>();
    final passingScore = (_questions.length * 0.7).ceil();
    appState.markMockExamCompleted(
      score: score,
      total: _questions.length,
      passingScore: passingScore,
      isMini: widget.isMini,
    );
    // 提出が完了したので一時保存データは不要になるため削除する
    appState.clearMockExamProgress();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MockExamResultScreen(
          score: score,
          total: _questions.length,
          passingScore: passingScore,
          questions: _questions,
          userAnswers: _answers,
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
                    icon: Icon(Icons.close, color: AppColors.textDim),
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

            // 一時保存バー(常時表示・タップで即保存)
            Material(
              color: AppColors.primaryFaint,
              child: InkWell(
                onTap: _isSaving ? null : _manualSave,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.save_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                      const SizedBox(width: 8),
                      const Text(
                        '一時保存する',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: AppFontSize.sm,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_currentIndex + 1}/${_questions.length}問 · いつでも再開可',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
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
                            style: TextStyle(
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
                                  style: TextStyle(
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
                        label: q.displayChoices[i],
                        state: selected
                            ? ChoiceState.selected
                            : ChoiceState.normal,
                        onTap: () {
                          setState(() => _answers[_currentIndex] = i);
                          _scheduleAutoSave();
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Question navigator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
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
                      onTap: () {
                        setState(() => _currentIndex = i);
                        _scheduleAutoSave();
                      },
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
        content: const Text(
          '「保存して中断する」を選ぶと、今の回答状況と残り時間がそのまま保存され、ホーム画面からいつでも同じ状態から再開できます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              await _saveProgress();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text(
              '保存して中断する',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
