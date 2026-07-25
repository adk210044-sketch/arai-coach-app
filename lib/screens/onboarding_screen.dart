import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/user_profile.dart';
import '../widgets/app_button.dart';
import 'main_tab_scaffold.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0: 受験区分, 1: 試験日, 2: 目標時間, 3: 通知
  ExamType _examType = ExamType.type1;
  DateTime _examDate = DateTime.now().add(const Duration(days: 52));
  double _goalMinutes = 20;
  bool _notificationsEnabled = true;

  static const int totalSteps = 4;

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
    appState.updateProfile(
      (p) => p.copyWith(notificationsEnabled: _notificationsEnabled),
    );
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
          style: const TextStyle(
            fontSize: AppFontSize.xxxxl,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: const TextStyle(
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

  Widget _examTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _illustration('🎓'),
        _sectionHeader(
          'STEP 1 / 4',
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
          'STEP 2 / 4',
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
                const Text(
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
                  style: const TextStyle(
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
                      style: const TextStyle(
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
          'STEP 3 / 4',
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
              const Row(
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

  Widget _notificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _illustration('🔔'),
        _sectionHeader('STEP 4 / 4', '通知でリマインドしますか?', '毎日決まった時間に学習を促す通知を送ります。'),
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
                  '学習リマインダーを受け取る',
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
      ],
    );
  }
}

const int kTotalQuestions = 1000;
