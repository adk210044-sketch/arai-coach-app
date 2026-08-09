// purchase_service.dart — Google Play Billing / Apple StoreKit 両対応の購入サービス。
//
// ▼ 事前に作成が必要な商品(サブスクリプション) ▼
//   商品ID: premium_monthly       (月額プレミアム / ¥1,200 / 1か月ごと)
//   商品ID: intensive_pack_3month (3か月集中パック / ¥2,600 / 3か月ごと)
//
//   [Android] Google Play Console で上記商品IDのサブスクリプションを作成し、
//   それぞれのbase planに「7日間無料トライアル」のオファーを設定すること。
//   オファーの有効化により、このサービスは価格0円のpricingPhaseを持つオファーを
//   自動検出して「トライアル付き購入」を行う。オファーが見つからない場合は
//   通常の(トライアルなし)base planへ自動フォールバックする。
//
//   [iOS] App Store Connect で同名の商品ID(premium_monthly /
//   intensive_pack_3month)の自動更新サブスクリプションを作成し、それぞれに
//   「Introductory Offer」として7日間無料の Free Trial を設定すること。
//   iOS側にはAndroidの「オファートークン」に相当する選択概念が無く、
//   StoreKitがユーザーの適格性(初回購入かどうか等)を自動判定してトライアルを
//   適用する。そのためこのコードからトライアル適用を明示的に強制することはできない。
//
// ▼ プラットフォーム分岐について ▼
//   Android: GooglePlayProductDetails / GooglePlayPurchaseParam を使用し、
//            offerToken を明示的に指定してオファー(トライアル有無)を選択する。
//   iOS    : 通常の ProductDetails / PurchaseParam を使用する。オファー選択は
//            行わず、StoreKit側の自動判定に委ねる。
//
// ▼ このサービスの制約(現時点でのスコープ) ▼
// - サーバーサイドでのレシート検証(Google Play Developer API / App Store Server API)
//   は行っていない。購入完了イベントをクライアント側でそのまま信頼してプラン反映する
//   簡易実装。不正対策・厳密な有効期限管理が必要になった場合は、Cloud Functions等で
//   購入トークン/レシートを検証するバックエンドの追加を推奨する。
// - Web環境(kIsWeb)では in_app_purchase が利用できないため、常に
//   isAvailable=false を返す。Web上のプレビューでは購入ボタンを押しても
//   実際の決済フローは開始されない(呼び出し元でモックへフォールバックすること)。
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../models/plan.dart';

/// 課金対象のプラン種別(Google Play商品IDと1:1対応)。
enum PurchasableProduct { premiumMonthly, intensivePack3month }

extension PurchasableProductX on PurchasableProduct {
  String get productId {
    switch (this) {
      case PurchasableProduct.premiumMonthly:
        return PurchaseService.idPremiumMonthly;
      case PurchasableProduct.intensivePack3month:
        return PurchaseService.idIntensivePack;
    }
  }

  /// このストア商品に対応する [PlanTier]。
  PlanTier get planTier {
    switch (this) {
      case PurchasableProduct.premiumMonthly:
        return PlanTier.premium;
      case PurchasableProduct.intensivePack3month:
        return PlanTier.intensivePack;
    }
  }
}

/// [PlanTier] から対応するストア商品を取得するためのヘルパー。
/// フリープランには対応する商品が無いため null を返す。
extension PlanTierPurchaseX on PlanTier {
  PurchasableProduct? get purchasableProduct {
    switch (this) {
      case PlanTier.free:
        return null;
      case PlanTier.premium:
        return PurchasableProduct.premiumMonthly;
      case PlanTier.intensivePack:
        return PurchasableProduct.intensivePack3month;
    }
  }
}

/// 購入結果をアプリ側(AppState)に伝えるためのイベントデータ。
class PurchaseResultEvent {
  final PurchasableProduct product;
  final bool isTrial;
  final bool isRestore;

  const PurchaseResultEvent({
    required this.product,
    required this.isTrial,
    required this.isRestore,
  });
}

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const String idPremiumMonthly = 'premium_monthly';
  static const String idIntensivePack = 'intensive_pack_3month';
  static const Set<String> _productIds = {idPremiumMonthly, idIntensivePack};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _initialized = false;
  bool _available = false;
  bool get isAvailable => _available;

  // 商品ID -> その商品に紐づく全オファー(base plan / トライアルオファー等)
  final Map<String, List<ProductDetails>> _offersByProductId = {};

  // 現在購入フロー中の商品ID -> トライアル希望有無(購入完了イベントに反映するため)
  final Map<String, bool> _pendingTrialFlag = {};

  /// 購入(新規/更新/復元)が完了した際に呼ばれる。
  void Function(PurchaseResultEvent event)? onPurchaseCompleted;

  /// エラー発生時にユーザー向けメッセージを渡す。
  void Function(String message)? onPurchaseError;

  /// 購入処理中(pending)であることを画面に伝える。
  void Function(bool pending)? onPendingChanged;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      _available = false;
      return;
    }

    try {
      _available = await _iap.isAvailable();
    } catch (_) {
      _available = false;
    }
    if (!_available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (Object error) {
        onPurchaseError?.call('購入処理の監視中にエラーが発生したよ: $error');
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        onPurchaseError?.call('商品情報の取得に失敗したよ: ${response.error!.message}');
      }
      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        debugPrint(
          'PurchaseService: 見つからなかった商品ID: ${response.notFoundIDs}'
          '(Google Play Console側の商品登録・審査状況を確認してね)',
        );
      }
      _offersByProductId.clear();
      for (final pd in response.productDetails) {
        _offersByProductId.putIfAbsent(pd.id, () => []).add(pd);
      }
    } catch (e) {
      onPurchaseError?.call('商品情報の取得に失敗したよ: $e');
    }
  }

  /// 指定商品の「価格0円のpricingPhaseを含むオファー」(=無料トライアルオファー)を探す。
  GooglePlayProductDetails? _findOfferWithTrial(String productId) {
    final offers = _offersByProductId[productId];
    if (offers == null) return null;
    for (final o in offers) {
      if (o is! GooglePlayProductDetails) continue;
      final idx = o.subscriptionIndex;
      if (idx == null) continue;
      final offerDetail = o.productDetails.subscriptionOfferDetails?[idx];
      if (offerDetail == null) continue;
      final hasFreePhase = offerDetail.pricingPhases.any(
        (p) => p.priceAmountMicros == 0,
      );
      if (hasFreePhase) return o;
    }
    return null;
  }

  /// 指定商品の「トライアルを含まない通常課金オファー」(base plan)を探す。
  GooglePlayProductDetails? _findBaseOffer(String productId) {
    final offers = _offersByProductId[productId];
    if (offers == null || offers.isEmpty) return null;
    for (final o in offers) {
      if (o is! GooglePlayProductDetails) continue;
      final idx = o.subscriptionIndex;
      if (idx == null) continue;
      final offerDetail = o.productDetails.subscriptionOfferDetails?[idx];
      if (offerDetail == null) continue;
      final hasFreePhase = offerDetail.pricingPhases.any(
        (p) => p.priceAmountMicros == 0,
      );
      if (!hasFreePhase) return o;
    }
    // トライアル無しオファーが見つからない場合は先頭を返す(フォールバック)
    final first = offers.first;
    return first is GooglePlayProductDetails ? first : null;
  }

  /// 商品情報(価格表示等)を取得済みか。
  bool hasProductInfo(PurchasableProduct product) =>
      _offersByProductId[product.productId]?.isNotEmpty ?? false;

  /// 表示用の価格文字列(Google Playから取得した実際の価格)。取得前はnull。
  String? formattedPrice(PurchasableProduct product) {
    final offer =
        _findBaseOffer(product.productId) ??
        _offersByProductId[product.productId]?.first;
    return offer?.price;
  }

  /// 購入フローを開始する。
  /// [withTrial] が true の場合、無料トライアルオファーがあればそれを使用し、
  /// 見つからない場合は自動的に通常課金にフォールバックする(Androidのみ選択可能)。
  /// iOSでは StoreKit がトライアル適用有無を自動判定するため、[withTrial] は
  /// 「ユーザーがトライアル付きのつもりで購入操作をした」という記録用フラグとして
  /// のみ扱う(実際に無料期間が付与されるかはApple側の適格性判定に依存する)。
  Future<void> buy(PurchasableProduct product, {bool withTrial = false}) async {
    if (!_available) {
      onPurchaseError?.call('この環境では購入機能を利用できないよ(Web版はプレビュー専用だよ)。');
      return;
    }
    final productId = product.productId;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _buyOnIOS(productId, withTrial: withTrial);
      return;
    }

    // Android(Google Play Billing): オファートークンを明示的に選択する。
    final GooglePlayProductDetails? chosen = withTrial
        ? (_findOfferWithTrial(productId) ?? _findBaseOffer(productId))
        : _findBaseOffer(productId);

    if (chosen == null) {
      onPurchaseError?.call('商品情報が見つからなかったよ。時間をおいて再度試してみてね。');
      return;
    }

    final actuallyTrial =
        withTrial && identical(chosen, _findOfferWithTrial(productId));
    _pendingTrialFlag[productId] = actuallyTrial;

    final param = GooglePlayPurchaseParam(
      productDetails: chosen,
      offerToken: chosen.offerToken,
    );

    try {
      onPendingChanged?.call(true);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      onPendingChanged?.call(false);
      onPurchaseError?.call('購入処理を開始できなかったよ: $e');
    }
  }

  /// iOS(App Store / StoreKit)向けの購入フロー。
  /// StoreKitにはAndroidのオファートークンに相当する選択肢が無いため、
  /// 商品ID一致の [ProductDetails] を1件取得してそのまま購入をリクエストする。
  /// Introductory Offer(無料トライアル)の適用有無はApple側が自動判定する。
  Future<void> _buyOnIOS(String productId, {required bool withTrial}) async {
    final offers = _offersByProductId[productId];
    final details = (offers != null && offers.isNotEmpty) ? offers.first : null;

    if (details == null) {
      onPurchaseError?.call('商品情報が見つからなかったよ。時間をおいて再度試してみてね。');
      return;
    }

    // ベストエフォートの記録用フラグ(実際の適用有無はApple側の判定次第)。
    _pendingTrialFlag[productId] = withTrial;

    final param = PurchaseParam(productDetails: details);

    try {
      onPendingChanged?.call(true);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      onPendingChanged?.call(false);
      onPurchaseError?.call('購入処理を開始できなかったよ: $e');
    }
  }

  /// 購入履歴の復元(機種変更・再インストール時など)。
  Future<void> restorePurchases() async {
    if (!_available) {
      onPurchaseError?.call('この環境では購入の復元を利用できないよ。');
      return;
    }
    try {
      await _iap.restorePurchases();
    } catch (e) {
      onPurchaseError?.call('購入の復元に失敗したよ: $e');
    }
  }

  PurchasableProduct? _productFromId(String productId) {
    if (productId == idPremiumMonthly) return PurchasableProduct.premiumMonthly;
    if (productId == idIntensivePack) {
      return PurchasableProduct.intensivePack3month;
    }
    return null;
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          onPendingChanged?.call(true);
          break;

        case PurchaseStatus.error:
          onPendingChanged?.call(false);
          onPurchaseError?.call(purchase.error?.message ?? '購入処理でエラーが発生したよ。');
          _pendingTrialFlag.remove(purchase.productID);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          onPendingChanged?.call(false);
          _pendingTrialFlag.remove(purchase.productID);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          onPendingChanged?.call(false);
          final product = _productFromId(purchase.productID);
          if (product != null) {
            final isRestore = purchase.status == PurchaseStatus.restored;
            final isTrial = !isRestore &&
                (_pendingTrialFlag[purchase.productID] ?? false);
            onPurchaseCompleted?.call(
              PurchaseResultEvent(
                product: product,
                isTrial: isTrial,
                isRestore: isRestore,
              ),
            );
          }
          _pendingTrialFlag.remove(purchase.productID);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
