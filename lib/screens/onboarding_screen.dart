import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../data/sample_data.dart';
import '../widgets/app_button.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/choice_item.dart';
import 'main_tab_scaffold.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0: 受験区分, 1: 試験日, 2: 目標時間, 3: 1問デモ, 4: 通知
  ExamType _examType = ExamType.type1;
  DateTime _examDate = DateTime.now().add(const Duration(days: 52));
  double _goalMinutes = 20;
  bool _notificationsEnabled = true;

  // 1問デモ用のローカル状態(演習セッションを開始せず単発で体験)
  late final Question _demoQuestion = sampleQuestionByFormat(
    QuestionFormat.choice5,
  );
  int? _demoSelected;
  bool _demoAnswered = false;

  static const int totalSteps = 5;

  void _next() {
    if (_step < totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  void _finish() {
    final appState = context.read<AppState>();
    appState.completeOnboarding(
      examType: _examType,
      examDate: _examDate,
      dailyGoalMinutes: _goalMinutes.round(),
    );
    if (_demoAnswered) {
      appState.markOnboardingDemoDone();
    }
    appState.setNotificationSettings(enabled: _notificationsEnabled);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainTabScaffold()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      color: AppColors.textDim,
                    ),
                  Expanded(
                    child: Row(
                      children: List.generate(totalSteps, (i) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            height: 5,
                            decoration: BoxDecoration(
                              color: i <= _step
                                  ? AppColors.primary
                                  : AppColors.borderSoft,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(child: _buildStepContent()),
              ),
              AppButton(
                label: _step == totalSteps - 1 ? '学習を始める' : '次へ',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _examTypeStep();
      case 1:
        return _examDateStep();
      case 2:
        return _goalStep();
      case 3:
        return _demoQuestionStep();
      default:
        return _notificationStep();
    }
  }

  Widget _sectionHeader(String stepLabel, String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepLabel,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: AppFontSize.base,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: AppFontSize.xxxxl,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: TextStyle(
            fontSize: AppFontSize.md,
            color: AppColors.textDim,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _illustration(String emoji) {
    return Container(
      height: 170,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 64)),
    );
  }

  Widget _coachWelcomeHero() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: AppShadow.card,
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipOval(
              child: Image.asset(
                'assets/characters/arai_coach_motivate.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'あ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'あらいコーチ',
            style: TextStyle(
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '合格まで、僕が全力で寄り添うよ!\n一緒に頑張ろうね。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.w600,
              height: 1.6,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _examTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _coachWelcomeHero(),
        _sectionHeader(
          'STEP 1 / 5',
          '受験区分を選んでください',
          '第一種・第二種でカバーする業務範囲が異なります。',
        ),
        Row(
          children: [
            Expanded(
              child: _examTypeCard(ExamType.type1, '第一種', '全業種対応・有害業務含む'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _examTypeCard(ExamType.type2, '第二種', '有害業務が少ない業種向け'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _examTypeCard(ExamType type, String label, String desc) {
    final selected = _examType == type;
    return GestureDetector(
      onTap: () => setState(() => _examType = type),
      child: Container(
        height: 108,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(
                fontSize: AppFontSize.base,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _examDateStep() {
    final now = DateTime.now();
    final minDate = now;
    final maxDate = now.add(const Duration(days: 365 * 3));
    final daysLeft = _examDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final weekdayNames = ['月', '火', '水', '木', '金', '土', '日'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _illustration('📅'),
        _sectionHeader(
          'STEP 2 / 5',
          '試験日を教えてください',
          '残り日数に合わせて、無理のない学習ペースを提案します。',
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _examDate,
                firstDate: minDate,
                lastDate: maxDate,
              );
              if (picked != null) setState(() => _examDate = picked);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '試験日',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textDim,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_examDate.year}年${_examDate.month}月${_examDate.day}日',
                  style: const TextStyle(
                    fontSize: AppFontSize.xxxxl,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${weekdayNames[_examDate.weekday - 1]}曜日',
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [30, 90, 180].map((d) {
            final label = d == 30 ? '1ヶ月後' : (d == 90 ? '3ヶ月後' : '6ヶ月後');
            final target = now.add(Duration(days: d));
            final active = _examDate.difference(target).inDays.abs() < 3;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _examDate = target),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: AppFontSize.base,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (daysLeft >= 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              border: Border.all(
                color: AppColors.yellow.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: AppFontSize.base,
                        height: 1.7,
                        color: AppColors.text,
                      ),
                      children: [
                        TextSpan(text: '残り'),
                        TextSpan(
                          text: '$daysLeft日',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: 'なら、1日あたり'),
                        TextSpan(
                          text:
                              '${((kTotalQuestions * 1.0) / (daysLeft == 0 ? 1 : daysLeft)).ceil()}問',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const TextSpan(text: 'のペースがおすすめです。'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _goalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _illustration('⏱️'),
        _sectionHeader(
          'STEP 3 / 5',
          '1日の学習目標時間',
          '5〜60分の間で、無理なく続けられる時間を設定しましょう。',
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Text(
                '${_goalMinutes.round()}分 / 日',
                style: const TextStyle(
                  fontSize: AppFontSize.xxxxxl,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.borderSoft,
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: _goalMinutes,
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: (v) => setState(() => _goalMinutes = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '5分',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textMute,
                    ),
                  ),
                  Text(
                    '60分',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textMute,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// STEP 4/5: 実際の問題を1問だけ体験するデモ。
  /// 「使い方がわからない」「実際にどんな問題か見たい」という不安を
  /// 本編開始前に解消するための、演習フローを使わない単発デモ表示。
  Widget _demoQuestionStep() {
    final q = _demoQuestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'STEP 4 / 5',
          'お試しで1問解いてみよう',
          'こんな感じで問題が出るよ。実際に触って雰囲気をつかんでみてね。',
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 14),
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
                  fontSize: AppFontSize.lg,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (q.items.isNotEmpty) ...[
                const SizedBox(height: 10),
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
          if (_demoAnswered) {
            if (q.isCorrectAnswer(i)) {
              state = ChoiceState.correct;
            } else if (i == _demoSelected) {
              state = ChoiceState.incorrect;
            }
          } else if (_demoSelected == i) {
            state = ChoiceState.selected;
          }
          return ChoiceItem(
            label: q.choices[i],
            state: state,
            onTap: _demoAnswered
                ? null
                : () => setState(() {
                    _demoSelected = i;
                    _demoAnswered = true;
                  }),
          );
        }),
        if (_demoAnswered) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: CoachBubble(
              mood: (_demoSelected != null && q.isCorrectAnswer(_demoSelected!))
                  ? CoachMood.correct
                  : CoachMood.incorrect,
              message: (_demoSelected != null && q.isCorrectAnswer(_demoSelected!))
                  ? '正解だよ!こんな感じで、解いたらすぐに解説が読めるんだ。'
                  : '惜しい!でも大丈夫、こうやってすぐ解説を確認できるのが強みだよ。\n\n${q.aiExplanation}',
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            '選択肢をタップして答えてみてね。',
            style: TextStyle(
              fontSize: AppFontSize.sm,
              color: AppColors.textMute,
            ),
          ),
        ],
      ],
    );
  }

  static const List<String> _reminderPreviewMessages = [
    '今日はまだ1問も解いてないみたい。5分だけでも一緒にやろうよ。',
    'コツコツ続けてるね!今日の分もサクッと済ませちゃおう。',
    '試験まであと少し。今日の分を忘れずにやっておこうね。',
  ];

  Widget _notificationStep() {
    final preview =
        _reminderPreviewMessages[DateTime.now().day %
            _reminderPreviewMessages.length];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _illustration('🔔'),
        _sectionHeader(
          'STEP 5 / 5',
          '通知でリマインドしますか?',
          '通知はすべて「あらいコーチ」からの優しい一言に統一しているよ。数字や催促っぽい文言は送らないから安心してね。',
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'あらいコーチからのリマインドを受け取る',
                  style: TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
            ],
          ),
        ),
        if (_notificationsEnabled) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '通知プレビュー',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                CoachBubble(mood: CoachMood.normal, message: preview),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

const int kTotalQuestions = 1000;
