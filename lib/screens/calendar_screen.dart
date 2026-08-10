import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../data/sample_data.dart';
import '../widgets/badge_detail_dialog.dart';
import '../widgets/badge_medal.dart';
import 'all_badges_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
  }

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final heatmap = appState.heatmap;

    final firstWeekday = DateTime(
      _viewMonth.year,
      _viewMonth.month,
      1,
    ).weekday; // 1=Mon
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final leading = firstWeekday - 1; // Mon start
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;
    final weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];
    final today = DateTime.now();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '学習カレンダー 🌱',
              style: TextStyle(
                fontSize: AppFontSize.xxxxl,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            // Streak hero
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9068), Color(0xFFFF5F6D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.streakDays}',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const Text(
                          '日連続で頑張ってる!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '最長 ${profile.longestStreak}日',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Weekly bars
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '直近14日の学習量',
                    style: TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(kStudyLog14.length, (i) {
                        final v = kStudyLog14[i];
                        final h = (v / 25).clamp(0.02, 1.0);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                FractionallySizedBox(
                                  heightFactor: h,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: v == 0
                                          ? AppColors.borderSoft
                                          : null,
                                      gradient: v == 0
                                          ? null
                                          : const LinearGradient(
                                              colors: [
                                                AppColors.primaryLight,
                                                AppColors.primary,
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${i + 11 > 24 ? i + 11 - 14 : i + 11}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textMute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Calendar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_viewMonth.year}年${_viewMonth.month}月',
                        style: const TextStyle(
                          fontSize: AppFontSize.xl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          _navButton(Icons.chevron_left, () {
                            setState(
                              () => _viewMonth = DateTime(
                                _viewMonth.year,
                                _viewMonth.month - 1,
                              ),
                            );
                          }),
                          const SizedBox(width: 4),
                          _navButton(Icons.chevron_right, () {
                            setState(
                              () => _viewMonth = DateTime(
                                _viewMonth.year,
                                _viewMonth.month + 1,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: weekdayLabels
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMute,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemCount: totalCells,
                    itemBuilder: (context, i) {
                      final dayNum = i - leading + 1;
                      final isValid = dayNum >= 1 && dayNum <= daysInMonth;
                      if (!isValid) return const SizedBox.shrink();
                      final date = DateTime(
                        _viewMonth.year,
                        _viewMonth.month,
                        dayNum,
                      );
                      final activity = heatmap[_key(date)] ?? 0;
                      final isToday =
                          date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day;
                      Color bg;
                      Color fg = AppColors.text;
                      if (activity == 0) {
                        bg = AppColors.bgSoft;
                      } else if (activity < 10) {
                        bg = const Color(0xFFDBEAFE);
                      } else if (activity < 20) {
                        bg = const Color(0xFF93C5FD);
                      } else {
                        bg = AppColors.primary;
                        fg = Colors.white;
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? Border.all(color: AppColors.accent, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 12,
                            color: fg,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '少ない',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textDim,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ...[
                        AppColors.bgSoft,
                        const Color(0xFFDBEAFE),
                        const Color(0xFF93C5FD),
                        AppColors.primary,
                      ].map(
                        (c) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '多い',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '獲得バッジ',
                  style: TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AllBadgesScreen()),
                  ),
                  child: Text(
                    '${appState.unlockedBadgeCount} / ${appState.totalBadgeCount} 個 →',
                    style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadow.card,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.64,
                ),
                itemCount: appState.badges.length > 6
                    ? 6
                    : appState.badges.length,
                itemBuilder: (context, i) {
                  final b = appState.badges[i];
                  return GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => BadgeDetailDialog(badge: b),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: b.unlocked
                            ? AppColors.primaryFaint
                            : AppColors.bgSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BadgeMedal(
                            badgeId: b.id,
                            unlocked: b.unlocked,
                            size: 80,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!b.unlocked)
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                '未達成',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMute,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.bgSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textDim),
      ),
    );
  }
}
