// ad_banner_placeholder.dart — フリープラン向けの実バナー広告ウィジェット
//
// AdMob(google_mobile_ads)を使った実際のバナー広告を表示する。
// - プレミアム/3か月集中パック加入中は非表示(SizedBox.shrink)。
// - Web版プレビューはAdMob未対応のため、広告なしで非表示にする
//   (Web版は開発・デモ用途であり、実際の広告配信対象はAndroid実機のみ)。
// - 広告読み込みに失敗した場合も非表示にし、レイアウト崩れを防ぐ。
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/ad_service.dart';

class AdBannerPlaceholder extends StatefulWidget {
  const AdBannerPlaceholder({super.key});

  @override
  State<AdBannerPlaceholder> createState() => _AdBannerPlaceholderState();
}

class _AdBannerPlaceholderState extends State<AdBannerPlaceholder> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadRequested = false;

  void _loadAd(double width) {
    if (_loadRequested || kIsWeb) return;
    _loadRequested = true;
    final ad = AdService.createBannerAd(
      width: width.truncate(),
      onLoaded: (_) {
        if (!mounted) return;
        setState(() => _isLoaded = true);
      },
      onFailed: (_, __) {
        if (!mounted) return;
        setState(() {
          _isLoaded = false;
          _bannerAd = null;
        });
      },
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isPremium) return const SizedBox.shrink();
    // Web版はAdMob未対応のため広告スペース自体を表示しない。
    if (kIsWeb) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    if (!_loadRequested) {
      // build中の setState を避けるため、フレーム確定後に読み込みを開始する。
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd(width));
    }

    if (!_isLoaded || _bannerAd == null) {
      // 読み込み中/失敗中はスペースを取らない(レイアウト崩れ防止)。
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
