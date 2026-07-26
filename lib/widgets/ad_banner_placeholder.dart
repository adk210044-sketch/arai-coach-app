// ad_banner_placeholder.dart — フリープラン向けの広告表示プレースホルダー
// 注: 実際の広告SDK(AdMob等)は未組み込み。フリープランの「広告モデル」を
// UI上で確認するためのモック表示。本番導入時はここをAdMobバナーに差し替える。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../screens/paywall_screen.dart';

class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isPremium) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(trigger: PaywallTrigger.general),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.bgSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.campaign_outlined,
                size: 18,
                color: AppColors.textMute,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '広告スペース(フリープラン)',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textMute,
                ),
              ),
            ),
            const Text(
              '広告なしにする →',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
