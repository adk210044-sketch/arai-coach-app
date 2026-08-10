// intensive_pack_promo_card.dart — フリープラン向け「3か月集中パック」訴求バナー
// 「フリー→3か月パック」の導線強化を目的とした、ホーム画面上部に表示する
// 目立つCTAカード。無料トライアル7日間の訴求を前面に出す。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../theme/app_colors_ext.dart';
import '../state/app_state.dart';
import '../models/plan.dart';
import '../screens/paywall_screen.dart';

class IntensivePackPromoCard extends StatelessWidget {
  const IntensivePackPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // プレミアム/集中パック契約中のユーザーには表示しない
    if (appState.isPremium) return const SizedBox.shrink();

    final packInfo = kPlanCatalog[PlanTier.intensivePack]!;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(trigger: PaywallTrigger.general),
        ),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.cardHover,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Image.asset(
                'assets/icons/goukaku_hanko.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🈴', style: TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          '7日間無料トライアル',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.text,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '3か月集中パックで一気に仕上げよう',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '全814問解放・AI優先復習・模擬試験も使い放題だよ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: AppFontSize.sm,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        packInfo.priceLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSize.xxl,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        packInfo.periodLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: AppFontSize.sm,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '買い切り・自動更新なし',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
