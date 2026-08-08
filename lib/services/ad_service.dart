// ad_service.dart — AdMobバナー広告の広告ユニットID管理と読み込みユーティリティ
//
// 広告ユニットIDはプラットフォーム別に管理する。Web版はAdMob未対応のため
// 呼び出し元でプラットフォーム判定してこのサービスの利用自体をスキップすること。
//
// 本番の広告ユニットID(Android バナー):
//   ca-app-pub-1683177610891884/1430926302
// 本番の広告ユニットID(iOS バナー):
//   ca-app-pub-1683177610891884/4719891470
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

class AdService {
  AdService._();

  /// AdMob管理画面で作成した本番バナー広告ユニットID(Android)。
  static const String _prodBannerUnitIdAndroid =
      'ca-app-pub-1683177610891884/1430926302';

  /// AdMob管理画面で作成した本番バナー広告ユニットID(iOS)。
  static const String _prodBannerUnitIdIos =
      'ca-app-pub-1683177610891884/4719891470';

  /// Google公式のテスト用バナー広告ユニットID(Android)。
  /// 実際の収益は発生しない、デバッグ/開発時専用のID。
  static const String _testBannerUnitIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  /// Google公式のテスト用バナー広告ユニットID(iOS)。
  static const String _testBannerUnitIdIos =
      'ca-app-pub-3940256099942544/2934735716';

  /// 現在の実行環境に応じたバナー広告ユニットIDを返す。
  /// デバッグビルドは常にGoogle公式テストIDを使用し、誤って本番IDで
  /// テスト用の無効クリックを発生させてAdMobアカウントが停止されるのを防ぐ。
  static String get bannerUnitId {
    final isIos = !kIsWeb && Platform.isIOS;
    if (kDebugMode) {
      return isIos ? _testBannerUnitIdIos : _testBannerUnitIdAndroid;
    }
    return isIos ? _prodBannerUnitIdIos : _prodBannerUnitIdAndroid;
  }

  /// バナー広告(アダプティブバナー)を1つ生成して返す。
  /// 呼び出し元は返り値の [BannerAd.load] を呼び、[BannerAd.dispose] を
  /// Widgetの破棄時に必ず呼ぶこと。
  static BannerAd createBannerAd({
    required int width,
    void Function(Ad ad)? onLoaded,
    void Function(Ad ad, LoadAdError error)? onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize(width: width, height: 50),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) debugPrint('✅ BannerAd loaded: ${ad.adUnitId}');
          onLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('❌ BannerAd failed to load: $error');
          }
          ad.dispose();
          onFailed?.call(ad, error);
        },
      ),
    );
  }
}
