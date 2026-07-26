import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/user_profile.dart';
import '../models/plan.dart';
import '../services/notification_service.dart';
import '../widgets/badge_detail_dialog.dart';
import '../widgets/coach_bubble.dart';
import 'paywall_screen.dart';
import 'coach_ai_settings_screen.dart';
import 'all_badges_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final accuracy = profile.totalAnswered == 0
        ? 0
        : (profile.totalCorrect / profile.totalAnswered * 100).round();

    final rows = <(Widget, String, String, VoidCallback?)>[
      (
        Text(
          profile.isPremium ? '👑' : '💎',
          style: const TextStyle(fontSize: 20),
        ),
        'プラン管理',
        kPlanCatalog[profile.planTier]!.label,
        () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
      ),
      (
        const CoachAvatar(size: 28),
        'あらいコーチのAI連携',
        'Gemini設定',
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CoachAiSettingsScreen()),
        ),
      ),
      (
        const Text('🎯', style: TextStyle(fontSize: 20)),
        '学習ゴール',
        '1日 ${profile.dailyGoalQuestions}問',
        null,
      ),
      (
        const Text('🔔', style: TextStyle(fontSize: 20)),
        'リマインダー(あらいコーチから優しく通知)',
        profile.notificationsEnabled ? profile.reminderTime : 'オフ',
        () => _openNotificationSettings(context, appState),
      ),
      (
        const Text('🔠', style: TextStyle(fontSize: 20)),
        '文字サイズ',
        profile.textSizeOption.label,
        () => _openTextSizeSettings(context, appState),
      ),
      (
        const Text('📅', style: TextStyle(fontSize: 20)),
        '試験日',
        profile.examDate != null
            ? '${profile.examDate!.month}/${profile.examDate!.day}'
            : '未設定',
        null,
      ),
      (
        const Text('🎓', style: TextStyle(fontSize: 20)),
        '受験区分',
        profile.examTypeLabel,
        () => _confirmExamTypeChange(context, appState, profile.examType),
      ),
      (const Text('🌙', style: TextStyle(fontSize: 20)), 'ダークモード', '自動', null),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName.substring(0, 1)
                              : '康',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile.displayName}さん',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppFontSize.xxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.examTypeLabel}衛生管理者',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: AppFontSize.sm,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                profile.isPremium
                                    ? '👑 ${kPlanCatalog[profile.planTier]!.label}'
                                    : 'Lv.8 · 熟練者',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statTile('${profile.totalAnswered}', '解答'),
                      const SizedBox(width: 6),
                      _statTile('$accuracy%', '正答率'),
                      const SizedBox(width: 6),
                      _statTile('${profile.streakDays}日', '連続'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!profile.isPremium) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    boxShadow: AppShadow.card,
                  ),
                  child: Row(
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '全問解放・模擬試験も使える',
                              style: TextStyle(
                                fontSize: AppFontSize.md,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'プレミアム/集中パックにアップグレード',
                              style: TextStyle(
                                fontSize: AppFontSize.sm,
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '実績バッジ',
                  style: TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${appState.unlockedBadgeCount} / ${appState.totalBadgeCount} 個獲得',
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadow.card,
              ),
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.95,
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
                          child: Opacity(
                            opacity: b.unlocked ? 1 : 0.4,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.icon,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b.name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AllBadgesScreen(),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: const Text(
                        'すべてのバッジを見る →',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: AppFontSize.base,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '設定',
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
                children: List.generate(rows.length, (i) {
                  final (icon, label, val, onTap) = rows[i];
                  return GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: i < rows.length - 1
                              ? const BorderSide(color: AppColors.borderSoft)
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: AppFontSize.md,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            val,
                            style: const TextStyle(
                              fontSize: AppFontSize.base,
                              color: AppColors.textDim,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textMute,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'ログアウト',
                  style: TextStyle(
                    color: AppColors.ng,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 「誤って違う種別を勉強しない」ための、受験区分変更前の明確な確認ダイアログ
  void _confirmExamTypeChange(
    BuildContext context,
    AppState appState,
    ExamType current,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('受験区分を変更しますか?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '現在: ${current == ExamType.type1 ? '第一種' : '第二種'}衛生管理者',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '第一種と第二種は出題範囲(有害業務の有無)が異なるよ。\n変更すると、これまでの学習履歴・正答率は該当する区分ごとに別々に保存されるから安心してね。',
                style: TextStyle(color: AppColors.textDim, height: 1.6),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: AppColors.textDim),
              ),
            ),
            TextButton(
              onPressed: () {
                final next = current == ExamType.type1
                    ? ExamType.type2
                    : ExamType.type1;
                appState.updateProfile((p) => p.copyWith(examType: next));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${next == ExamType.type1 ? '第一種' : '第二種'}に切り替えたよ',
                    ),
                  ),
                );
              },
              child: const Text(
                '切り替える',
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

  // 通知設定(ON/OFF・リマインド時刻)。トグルすると実際に権限リクエスト&
  // ローカル通知のスケジュール更新まで行う。
  void _openNotificationSettings(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final profile = appState.profile;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔔 リマインダー設定',
                      style: TextStyle(
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'あらいコーチからの優しい一言だけを送るよ。数字や催促っぽい文言は送らないから安心してね。',
                      style: TextStyle(
                        fontSize: AppFontSize.sm,
                        color: AppColors.textDim,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'リマインドを受け取る',
                              style: TextStyle(
                                fontSize: AppFontSize.md,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Switch(
                            value: profile.notificationsEnabled,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) async {
                              await appState.setNotificationSettings(
                                enabled: v,
                              );
                              setSheetState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    if (profile.notificationsEnabled) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '通知時刻',
                                style: TextStyle(
                                  fontSize: AppFontSize.md,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final parts = profile.reminderTime.split(':');
                                final initial = TimeOfDay(
                                  hour: int.tryParse(parts[0]) ?? 21,
                                  minute:
                                      int.tryParse(
                                        parts.length > 1 ? parts[1] : '0',
                                      ) ??
                                      0,
                                );
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: initial,
                                );
                                if (picked != null) {
                                  final hh = picked.hour.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  final mm = picked.minute.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  await appState.setNotificationSettings(
                                    enabled: true,
                                    reminderTime: '$hh:$mm',
                                  );
                                  setSheetState(() {});
                                }
                              },
                              child: Text(
                                profile.reminderTime,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppFontSize.md,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await NotificationService.showTestNotification();
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('テスト通知を送ったよ。通知欄を確認してみてね'),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                          child: const Text(
                            'テスト通知を送る',
                            style: TextStyle(color: AppColors.textDim),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 文字サイズ設定(標準/大きい)。「文字が小さい」という声への対応。
  void _openTextSizeSettings(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔠 文字サイズ',
                  style: TextStyle(
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '見やすいサイズに切り替えられるよ。アプリ全体に反映されるよ。',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textDim,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                ...TextSizeOption.values.map((option) {
                  final selected = appState.profile.textSizeOption == option;
                  return GestureDetector(
                    onTap: () {
                      appState.setTextSizeOption(option);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryFaint
                            : AppColors.bgSoft,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'A',
                            style: TextStyle(
                              fontSize: option == TextSizeOption.large
                                  ? 22
                                  : 15,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option.label,
                              style: TextStyle(
                                fontSize: AppFontSize.md,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.text,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMute,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statTile(String value, String label) {
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
                fontSize: 16,
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
}
