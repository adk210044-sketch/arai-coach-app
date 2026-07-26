// paywall_screen.dart — 料金プラン選択・ペイウォールUI
// 注: 現時点では実際のストア課金(Google Play Billing等)は組み込んでおらず、
// プラン選択はローカル状態(モック)を切り替えるのみ。実装はUI/ロジックの検証用。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/plan.dart';
import '../models/user_profile.dart';
import '../widgets/coach_bubble.dart';

/// ペイウォール表示のきっかけ(どの機能をタップして遷移してきたか)を
/// メッセージに反映するための種別。
enum PaywallTrigger { general, mockExam, questionLimit, explanation }

class PaywallScreen extends StatefulWidget {
  final PaywallTrigger trigger;

  const PaywallScreen({super.key, this.trigger = PaywallTrigger.general});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PlanTier _selected = PlanTier.intensivePack;

  String get _coachMessage {
    switch (widget.trigger) {
      case PaywallTrigger.mockExam:
        return '模擬試験はプレミアム限定の機能だよ。\nプランに入ると本番形式で\nしっかり実力チェックできるようになるよ。';
      case PaywallTrigger.questionLimit:
        return 'フリープランは過去問50問までなんだ。\n続きから解きたいときは\nプランをアップグレードしてみてね。';
      case PaywallTrigger.explanation:
        return 'この先の解説はプレミアム限定だよ。\nAI解説を全部見られるようになると\n理解がぐっと深まるよ。';
      case PaywallTrigger.general:
        return '僕が一緒に、合格までしっかりサポートするよ。\n自分に合ったプランを\n選んでみてね。';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        backgroundColor: AppColors.bgSoft,
        elevation: 0,
        title: const Text(
          'プラン管理',
          style: TextStyle(
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 現在のプラン状態
              _currentPlanBanner(profile),
              const SizedBox(height: 16),

              // あらいコーチのメッセージ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadow.card,
                ),
                child: CoachBubble(
                  mood: CoachMood.motivate,
                  message: _coachMessage,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '機能でパッと比較',
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'プランの違いが一目でわかるよ',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 10),
              _featureComparisonTable(),
              const SizedBox(height: 22),

              const Text(
                'プランを選ぶ',
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              _planCard(context, PlanTier.intensivePack, appState),
              const SizedBox(height: 12),
              _planCard(context, PlanTier.premium, appState),
              const SizedBox(height: 12),
              _planCard(context, PlanTier.free, appState),

              const SizedBox(height: 20),
              _ctaButton(context, appState, profile),

              const SizedBox(height: 14),
              Center(
                child: Text(
                  '実際の決済は準備中だよ。今はプラン選択のUI確認だけできるよ。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMute,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (profile.isPremium)
                Center(
                  child: TextButton(
                    onPressed: () => _confirmCancel(context, appState),
                    child: const Text(
                      'プランを解約する(フリープランに戻す)',
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
      ),
    );
  }

  Widget _currentPlanBanner(UserProfile profile) {
    final info = kPlanCatalog[profile.planTier]!;
    final remaining = profile.planDaysRemaining;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              profile.isPremium ? '👑' : '🌱',
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '現在のプラン: ${info.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.isPremium
                      ? (remaining != null
                            ? '${profile.planIsTrial ? '無料トライアル残り' : '有効期限まで'} $remaining日'
                            : '有効期限なし')
                      : '過去問${AppStateFreeLimitLabel.limit}問まで利用できるよ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: AppFontSize.sm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 「機能でパッと比較」テーブル。
  /// 縦軸=機能、横軸=3プラン(フリー/プレミアム/集中パック)で、
  /// アイコン+レベル記号(✓/△/✕)を並べてプランの違いが一目でわかるようにする。
  /// 現在の受験区分の実問題数を反映した比較表データ。
  List<PlanFeatureRow> get _featureMatrix {
    final appState = context.read<AppState>();
    return buildPlanFeatureMatrix(
      totalQuestionCount: appState.totalQuestionCountForCurrentExamType,
      freeQuestionLimit: AppState.freeQuestionLimit,
    );
  }

  Widget _featureComparisonTable() {
    const tiers = [PlanTier.free, PlanTier.premium, PlanTier.intensivePack];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        children: [
          // ヘッダー行: 機能列 + 3プラン名
          Row(
            children: [
              const SizedBox(width: 34), // アイコン分のスペース
              const Expanded(flex: 3, child: SizedBox()),
              for (final t in tiers)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text(
                        t.shortLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: t == PlanTier.free
                              ? AppColors.textMute
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        t == PlanTier.free
                            ? '¥0'
                            : t == PlanTier.premium
                            ? '¥1,200/月'
                            : '¥2,600/3M',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textMute,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: AppColors.borderSoft, height: 1),
          for (final row in _featureMatrix) _featureRow(row, tiers),
        ],
      ),
    );
  }

  Widget _featureRow(PlanFeatureRow row, List<PlanTier> tiers) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(row.icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              row.label,
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          for (final t in tiers) Expanded(flex: 3, child: _featureCell(row, t)),
        ],
      ),
    );
  }

  Widget _featureCell(PlanFeatureRow row, PlanTier tier) {
    final level = row.level[tier] ?? FeatureLevel.none;
    final valueText = row.valueLabel?[tier];

    IconData icon;
    Color color;
    switch (level) {
      case FeatureLevel.full:
        icon = Icons.check_circle;
        color = AppColors.ok;
        break;
      case FeatureLevel.partial:
        icon = Icons.change_history;
        color = AppColors.yellow;
        break;
      case FeatureLevel.none:
        icon = Icons.close;
        color = AppColors.textMute;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        if (valueText != null) ...[
          const SizedBox(height: 2),
          Text(
            valueText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textDim,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _planCard(BuildContext context, PlanTier tier, AppState appState) {
    final info = kPlanCatalog[tier]!;
    final selected = _selected == tier;
    final isCurrent =
        appState.profile.planTier == tier && appState.profile.isPremium ||
        (tier == PlanTier.free && !appState.profile.isPremium);

    return GestureDetector(
      onTap: () => setState(() => _selected = tier),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadow.cardHover : AppShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        info.label,
                        style: const TextStyle(
                          fontSize: AppFontSize.lg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (info.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            info.badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFaint,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      '利用中',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? AppColors.primary : AppColors.textMute,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: info.priceLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: info.periodLabel,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: AppFontSize.base,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              info.subtitle,
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textDim,
              ),
            ),
            if (info.hasFreeTrial) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    size: 14,
                    color: AppColors.ok,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${info.trialDays}日間無料トライアルあり',
                    style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.ok,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            ...info.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      tier == PlanTier.free
                          ? Icons.circle_outlined
                          : Icons.check_circle,
                      size: 14,
                      color: tier == PlanTier.free
                          ? AppColors.textMute
                          : AppColors.ok,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textDim,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctaButton(
    BuildContext context,
    AppState appState,
    UserProfile profile,
  ) {
    final info = kPlanCatalog[_selected]!;
    final alreadyOnThis =
        profile.planTier == _selected &&
        (profile.isPremium || _selected == PlanTier.free);
    final showTrialCta =
        _selected == PlanTier.intensivePack &&
        !profile.trialUsed &&
        !alreadyOnThis;

    String label;
    if (alreadyOnThis) {
      label = '現在利用中のプランだよ';
    } else if (_selected == PlanTier.free) {
      label = 'フリープランに切り替える';
    } else if (showTrialCta) {
      label = '${info.trialDays}日間無料で試す';
    } else {
      label = '${info.label}(${info.priceLabel}${info.periodLabel})に申し込む';
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: alreadyOnThis
            ? null
            : () => _confirmSelect(context, appState, showTrialCta),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _confirmSelect(
    BuildContext context,
    AppState appState,
    bool startTrial,
  ) {
    final info = kPlanCatalog[_selected]!;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(startTrial ? '無料トライアルを始めるよ' : '${info.label}に申し込むよ'),
          content: Text(
            startTrial
                ? '${info.trialDays}日間は無料で全機能を使えるよ。期間が終わると自動で有料プランに切り替わる想定だけど、今はモック実装なので実際の課金は発生しないよ。'
                : '${info.priceLabel}${info.periodLabel}のプランに切り替えるよ(現在は決済処理のモック実装のため、実際の課金は発生しないよ)。',
            style: const TextStyle(color: AppColors.textDim, height: 1.6),
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
                appState.selectPlan(_selected, startTrial: startTrial);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      startTrial
                          ? '無料トライアルを開始したよ!存分に使ってみてね'
                          : '${info.label}に切り替えたよ。ありがとう!',
                    ),
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text(
                '決定する',
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

  void _confirmCancel(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('プランを解約しますか?'),
          content: const Text(
            '解約すると、フリープラン(過去問50問まで)に戻るよ。学習の記録はそのまま残るから安心してね。',
            style: TextStyle(color: AppColors.textDim, height: 1.6),
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
                appState.cancelPlan();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('フリープランに切り替えたよ')));
              },
              child: const Text(
                '解約する',
                style: TextStyle(
                  color: AppColors.ng,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// フリープランの上限を画面表示用に持つための小さなヘルパー。
class AppStateFreeLimitLabel {
  static const int limit = 50;
}
