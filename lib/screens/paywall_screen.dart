// paywall_screen.dart — 料金プラン選択・ペイウォールUI
// Android実機ではGoogle Play Billing(in_app_purchase)経由での実購入を行う。
// Web版プレビュー等、ストア課金が利用できない環境ではローカル状態を切り替える
// モック実装に自動フォールバックする(AppState.startStorePurchaseがfalseを返す場合)。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/plan.dart';
import '../models/user_profile.dart';
import '../widgets/coach_bubble.dart';

/// 利用規約・プライバシーポリシーの公開URL。
/// Apple/Googleの定期購読(サブスクリプション)ガイドラインにより、
/// 購入画面内に両方への機能するリンクを設置する必要がある。
const String kTermsOfServiceUrl =
    'https://adk210044-sketch.github.io/arai-coach-app/terms-of-service.html';
const String kPrivacyPolicyUrl =
    'https://adk210044-sketch.github.io/arai-coach-app/privacy-policy.html';

Future<void> _openExternalLink(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().ensurePurchaseServiceInitialized();
    });
  }

  String get _coachMessage {
    switch (widget.trigger) {
      case PaywallTrigger.mockExam:
        return '模擬試験はプレミアム限定の機能だよ。\nプランに入ると本番形式で\nしっかり実力チェックできるようになるよ。';
      case PaywallTrigger.questionLimit:
        return 'フリープランは過去問50問までなんだ。\n続きから解きたいときは\nプランをアップグレードしてみてね。';
      case PaywallTrigger.explanation:
        return 'この先の解説はプレミアム限定だよ。\nAI解説を全部見られるようになると\n理解がぐっと深まるよ。';
      case PaywallTrigger.general:
        return '僕が一緒に、合格までしっかりサポートするよ。\n自分に合ったプランを選んでみてね。';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;

    // 購入結果メッセージ(成功/エラー)を1回だけSnackBarで表示する。
    if (appState.purchaseSuccessMessage != null ||
        appState.purchaseErrorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final success = appState.purchaseSuccessMessage;
        final error = appState.purchaseErrorMessage;
        appState.clearPurchaseMessages();
        if (success != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(success)));
        } else if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.ng),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        backgroundColor: AppColors.bgSoft,
        elevation: 0,
        title: Text(
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

              // 無料トライアルの入口(未利用・フリープランのユーザーのみ表示)
              _freeTrialSection(context, appState, profile),

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
              Text(
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
                child: TextButton(
                  onPressed: () async {
                    await appState.restoreStorePurchases();
                  },
                  child: Text(
                    '購入を復元する',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: AppFontSize.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              if (profile.isPremium)
                Center(
                  child: TextButton(
                    onPressed: () => _confirmCancel(context, appState),
                    child: Text(
                      'プランを解約する(フリープランに戻す)',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: AppFontSize.base,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              _subscriptionLegalFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// サブスクリプション契約条件(自動更新・解約方法)と、利用規約/
  /// プライバシーポリシーへの機能するリンクを表示するフッター。
  /// Apple Guideline 3.1.2(c) / Google Playの定期購読要件対応。
  Widget _subscriptionLegalFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '定期購読について',
            style: TextStyle(
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w700,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'プレミアム(¥1,200/月)・集中パック(¥2,600/3か月)は自動更新の'
            '定期購読です。期間終了の24時間前までに解約しない場合、'
            '同一期間で自動的に更新され、購読しているストアアカウントに'
            '課金されます。解約はご利用の端末のストア(App Store / Google Play)'
            'の定期購入管理画面からいつでも行えます。',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMute,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              GestureDetector(
                onTap: () => _openExternalLink(kTermsOfServiceUrl),
                child: Text(
                  '利用規約',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openExternalLink(kPrivacyPolicyUrl),
                child: Text(
                  'プライバシーポリシー',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
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
                        style: TextStyle(
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
              style: TextStyle(
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
            style: TextStyle(
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
                    style: TextStyle(
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
              style: TextStyle(
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
                        style: TextStyle(
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

  /// 一番上のパナー: 未利用・フリープランのユーザーに向けて、
  /// 7日間の無料トライアルを入口として提供する。
  /// タプすると・・・CTAWidgetが、トライアル終了後に切り替えるプラン(月額
  /// または3か月)を選ばせるボトムシートを開く。
  Widget _freeTrialSection(
    BuildContext context,
    AppState appState,
    UserProfile profile,
  ) {
    if (profile.isPremium || profile.trialUsed) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.cardHover,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.card_giftcard, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'まずは7日間無料で試してみる',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'トライアル終了後に使いたいプラン(月額 or 3か月)を選ぶだけ。\n期間中はいつでも解約できるよ。',
            style: TextStyle(
              color: Colors.white,
              height: 1.5,
              fontSize: AppFontSize.sm,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _showTrialPlanPicker(context, appState),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: const Text(
                '7日間無料トライアルを始める',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: AppFontSize.base,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// トライアル終了後に切り替わるプラン(月額 or 3か月)を選ばせるボトムシート。
  void _showTrialPlanPicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'トライアル終了後のプランを選んでね',
                  style: TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '7日間は無料。期間終了後、選んだプランで自動的に始まるよ。',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textDim,
                  ),
                ),
                const SizedBox(height: 16),
                _trialOptionTile(sheetCtx, appState, PlanTier.premium),
                const SizedBox(height: 10),
                _trialOptionTile(sheetCtx, appState, PlanTier.intensivePack),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _trialOptionTile(
    BuildContext sheetContext,
    AppState appState,
    PlanTier tier,
  ) {
    final info = kPlanCatalog[tier]!;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () {
        Navigator.of(sheetContext).pop();
        _confirmStartTrial(context, appState, tier);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        info.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppFontSize.base,
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
                  const SizedBox(height: 2),
                  Text(
                    'トライアル終了後 ${info.priceLabel}${info.periodLabel}',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMute),
          ],
        ),
      ),
    );
  }

  void _confirmStartTrial(
    BuildContext context,
    AppState appState,
    PlanTier tier,
  ) {
    final info = kPlanCatalog[tier]!;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('無料トライアルを始めるよ'),
          content: Text(
            '7日間は無料で全機能を使えるよ。期間が終わると自動的に${info.label}'
            '(${info.priceLabel}${info.periodLabel})に切り替わって課金が始まるから、\n'
            '不要な場合は期間内にPlayストアの定期購入管理画面から解約してね。',
            style: TextStyle(color: AppColors.textDim, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('キャンセル', style: TextStyle(color: AppColors.textDim)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final started = await appState.startStorePurchase(
                  tier,
                  withTrial: true,
                );
                if (!started) {
                  appState.selectPlan(tier, startTrial: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('無料トライアルを開始したよ!(プレビュー環境のため決済はモックだよ)'),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'トライアルを始める',
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

  Widget _ctaButton(
    BuildContext context,
    AppState appState,
    UserProfile profile,
  ) {
    final info = kPlanCatalog[_selected]!;
    final alreadyOnThis =
        profile.planTier == _selected &&
        (profile.isPremium || _selected == PlanTier.free);

    String label;
    if (alreadyOnThis) {
      label = '現在利用中のプランだよ';
    } else if (_selected == PlanTier.free) {
      label = 'フリープランに切り替える';
    } else {
      label = '${info.label}(${info.priceLabel}${info.periodLabel})に申し込む';
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (alreadyOnThis || appState.purchaseInProgress)
            ? null
            : () => _confirmSelect(context, appState),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        child: appState.purchaseInProgress
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  void _confirmSelect(BuildContext context, AppState appState) {
    final tier = _selected;
    final info = kPlanCatalog[tier]!;

    if (tier == PlanTier.free) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('フリープランに切り替えますか?'),
            content: Text(
              '有料プランを解約して、フリープラン(同じ過去問50問を繰り返し利用)に戻るよ。学習の記録はそのまま残るから安心してね。',
              style: TextStyle(color: AppColors.textDim, height: 1.6),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'キャンセル',
                  style: TextStyle(color: AppColors.textDim),
                ),
              ),
              TextButton(
                onPressed: () {
                  appState.cancelPlan();
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('フリープランに切り替えたよ')),
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
      return;
    }

    // 3か月パック(上位プラン)から月額プレミアム(下位プラン)への切り替えは
    // Appleの仕様上「ダウングレード」扱いとなり、現在支払い済みの3か月分の
    // 期間が終わるまで反映されない(=すぐには切り替わらない)。
    // 事前にその旨を案内し、「不具合では?」という誤解を防ぐ。
    final currentProfile = appState.profile;
    final isDowngradeFromIntensive =
        tier == PlanTier.premium &&
        currentProfile.planTier == PlanTier.intensivePack &&
        currentProfile.isPremium;

    final dialogMessage = isDowngradeFromIntensive
        ? '現在お申し込み中の3か月パックの期間が残っているよ。\n'
              'その期間が終わったあとに月額プレミアム(${info.priceLabel}${info.periodLabel})'
              'へ自動的に切り替わるから、今すぐ変わるわけではない点だけ注意してね。'
        : '${info.priceLabel}${info.periodLabel}で今すぐ申し込むよ。\n'
              'トライアルを試したい場合は、キャンセルして上の「7日間無料トライアルを始める」から進めてね。';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${info.label}に申し込むよ'),
          content: Text(
            dialogMessage,
            style: TextStyle(color: AppColors.textDim, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('キャンセル', style: TextStyle(color: AppColors.textDim)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final started = await appState.startStorePurchase(
                  tier,
                  withTrial: false,
                );
                if (!started) {
                  appState.selectPlan(tier, startTrial: false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${info.label}に切り替えたよ。ありがとう!(プレビュー環境のため決済はモックだよ)',
                        ),
                      ),
                    );
                  }
                }
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
          content: Text(
            '解約すると、フリープラン(同じ過去問50問を繰り返し利用)に戻るよ。学習の記録はそのまま残るから安心してね。',
            style: TextStyle(color: AppColors.textDim, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('キャンセル', style: TextStyle(color: AppColors.textDim)),
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
