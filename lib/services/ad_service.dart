// ad_service.dart — AdMobバナー広告の広告ユニットID管理と読み込みユーティリティ
//
// 広告ユニットIDはプラットフォーム別に管理する。Web版はAdMob未対応のため
// 呼び出し元でプラットフォーム判定してこのサービスの利用自体をスキップすること。
//
// 本番の広告ユニットID(Android バナー):
//   ca-app-pub-1683177610891884/1430926302
// 本番の広告ユニットID(iOS バナー):
//   ※iOS未発行。AdMob管理画面で「iOSアプリ」を追加登録後、バナー広告ユニットを
//   新規作成し、発行されたIDを _prodBannerUnitIdIos に設定すること。
//   未設定の間はテストIDにフォールバックし、実際の広告配信は行われない。
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

class AdService {
  AdService._();

  /// AdMob管理画面で作成した本番バナー広告ユニットID(Android)。
  static const String _prodBannerUnitIdAndroid =
      'ca-app-pub-1683177610891884/1430926302';

  /// AdMob管理画面で作成した本番バナー広告ユニットID(iOS)。
  /// TODO: iOSアプリをAdMobに追加登録後、実際の広告ユニットIDに置き換える。
  static const String _prodBannerUnitIdIos =
      'ca-app-pub-1683177610891884/YYYYYYYYYY';

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
  /// また、iOS用の本番IDが未設定(仮のYから始まる値)の間は、
  /// 誤ってリジェクトされるプレースホルダーIDを送らないようテストIDにフォールバックする。
  static String get bannerUnitId {
    final isIos = !kIsWeb && Platform.isIOS;
    if (kDebugMode) {
      return isIos ? _testBannerUnitIdIos : _testBannerUnitIdAndroid;
    }
    if (isIos) {
      // iOS本番IDが未設定(プレースホルダーのまま)ならテストIDにフォールバック
      if (_prodBannerUnitIdIos.contains('YYYYYYYYYY')) {
        return _testBannerUnitIdIos;
      }
      return _prodBannerUnitIdIos;
    }
    return _prodBannerUnitIdAndroid;
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
