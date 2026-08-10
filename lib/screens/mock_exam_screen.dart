import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../theme/app_colors_ext.dart';
import '../state/app_state.dart';
import '../models/user_profile.dart';
import 'mock_exam_session_screen.dart';
import 'paywall_screen.dart';

class MockExamScreen extends StatelessWidget {
  const MockExamScreen({super.key});

  void _startOrPaywall(
    BuildContext context, {
    required int questionCount,
    required int durationSec,
  }) {
    final appState = context.read<AppState>();
    if (!appState.canUseMockExam) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(trigger: PaywallTrigger.mockExam),
        ),
      );
      return;
    }
    if (appState.hasSavedMockExam) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('進行中の模試があります'),
          content: const Text('新しく始めると、保存されている進行状況は削除されます。よろしいですか?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await appState.clearMockExamProgress();
                if (!ctx.mounted) return;
                _pushSession(
                  context,
                  questionCount: questionCount,
                  durationSec: durationSec,
                );
              },
              child: const Text(
                '新しく始める',
                style: TextStyle(
                  color: AppColors.ng,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    _pushSession(
      context,
      questionCount: questionCount,
      durationSec: durationSec,
    );
  }

  void _pushSession(
    BuildContext context, {
    required int questionCount,
    required int durationSec,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MockExamSessionScreen(
          questionCount: questionCount,
          durationSec: durationSec,
        ),
      ),
    );
  }

  void _resume(BuildContext context, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MockExamSessionScreen(
          questionCount: data['questionCount'] as int,
          durationSec: data['durationSec'] as int,
          resumeData: data,
        ),
      ),
    );
  }

  String _fmtSec(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isPremium = appState.canUseMockExam;
    final isType2 = appState.profile.examType == ExamType.type2;
    // 本番と同じ出題数: 第一種44問 / 第二種30問(いずれも試験時間3時間)
    final fullQuestionCount = isType2 ? 30 : 44;
    final savedProgress = appState.savedMockExamProgress;
    return Scaffold(
      backgroundColor: context.appColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: context.appColors.surfaceSoft,
        title: Text(
          '模擬試験',
          style: TextStyle(
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w700,
            color: context.appColors.text,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本番と同じ形式で実力チェック',
                style: TextStyle(
                  fontSize: AppFontSize.base,
                  color: context.appColors.textDim,
                ),
              ),
              const SizedBox(height: 18),

              // 進行中の模試がある場合、再開カードを表示(180分を中断せず続けるのは
              // 難しいという声への対応。回答ごとに自動保存された状態から再開できる)
              if (savedProgress != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFaint,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.play_circle_fill,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '進行中の模試があります',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: AppFontSize.md,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(savedProgress['currentIndex'] as int? ?? 0) + 1}/'
                        '${savedProgress['questionCount']}問目まで回答済み'
                        ' · 残り${_fmtSec(savedProgress['remainingSec'] as int? ?? 0)}',
                        style: TextStyle(
                          fontSize: AppFontSize.sm,
                          color: context.appColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => _resume(context, savedProgress),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                          child: const Text(
                            '再開する',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: AppFontSize.base,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Hero
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        isPremium ? 'おすすめ ⭐' : '👑 プレミアム限定',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'フル模擬試験',
                      style: TextStyle(
                        fontSize: AppFontSize.xxxxl,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$fullQuestionCount問 · 3時間 · 本番と同構成',
                      style: TextStyle(
                        fontSize: AppFontSize.base,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _statBox('$fullQuestionCount問', '出題数'),
                        const SizedBox(width: 8),
                        _statBox('180分', '時間'),
                        const SizedBox(width: 8),
                        _statBox('70%', '合格ライン'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => _startOrPaywall(
                          context,
                          questionCount: fullQuestionCount,
                          durationSec: 180 * 60,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Text(
                          isPremium ? '受験を始める' : '🔒 プレミアムで受験する',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Mini mock
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppShadow.card,
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ミニ模試 (10問)',
                            style: TextStyle(
                              fontSize: AppFontSize.lg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'スキマ時間で15分',
                            style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: context.appColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _startOrPaywall(
                        context,
                        questionCount: 10,
                        durationSec: 15 * 60,
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryFaint,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        isPremium ? '開始' : '🔒 開始',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '受験履歴',
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadow.card,
                ),
                child: Column(
                  children: [
                    _historyRow(
                      context,
                      '10月18日',
                      72,
                      'B',
                      AppColors.yellow,
                      '合格圏まであと少し!',
                    ),
                    _historyRow(
                      context,
                      '10月10日',
                      65,
                      'C',
                      const Color(0xFFF97316),
                      'コツコツ伸びてる',
                    ),
                    _historyRow(
                      context,
                      '10月2日',
                      58,
                      'D',
                      AppColors.ng,
                      '初回チャレンジ',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(
    BuildContext context,
    String date,
    int score,
    String judge,
    Color color,
    String msg, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: context.appColors.borderSoft),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              judge,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg,
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: context.appColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$score',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: '%',
                  style: TextStyle(
                    color: context.appColors.textDim,
                    fontSize: 11,
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
