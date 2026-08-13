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
//   Android: ProductSubscriptionAndroid.subscriptionOffers から
//            offerTokenAndroid を明示的に指定してオファー(トライアル有無)を選択する。
//   iOS    : ProductSubscriptionIOS を使用する。オファー選択は行わず、
//            StoreKit側の自動判定に委ねる。
//
// ▼ このサービスの制約(現時点でのスコープ) ▼
// - サーバーサイドでのレシート検証(Google Play Developer API / App Store Server API)
//   は行っていない。購入完了イベントをクライアント側でそのまま信頼してプラン反映する
//   簡易実装。不正対策・厳密な有効期限管理が必要になった場合は、Cloud Functions等で
//   購入トークン/レシートを検証するバックエンドの追加を推奨する。
// - Web環境(kIsWeb)では flutter_inapp_purchase が利用できないため、常に
//   isAvailable=false を返す。Web上のプレビューでは購入ボタンを押しても
//   実際の決済フローは開始されない(呼び出し元でモックへフォールバックすること)。
//
// ▼ 実装ベース ▼
//   Google Play Billing Library 7以前を使う in_app_purchase_android は
//   Billing Library 8.0.0での破壊的変更(queryPurchaseHistoryAsync削除)により
//   将来動作しなくなるため、OpenIAP標準ベースの flutter_inapp_purchase
//   (内部でBilling Library 9.1.0を使用)へ移行済み。
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import '../models/plan.dart';

/// 課金対象のプラン種別(ストア商品IDと1:1対応)。
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
  static const List<String> _productIds = [idPremiumMonthly, idIntensivePack];

  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;
  StreamSubscription<Purchase>? _purchaseSub;
  StreamSubscription<PurchaseError>? _errorSub;

  bool _initialized = false;
  bool _available = false;
  bool get isAvailable => _available;

  // 商品ID -> Android用サブスクリプション商品情報(オファー一覧を含む)
  final Map<String, ProductSubscriptionAndroid> _androidProductsById = {};

  // 商品ID -> iOS用サブスクリプション商品情報
  final Map<String, ProductSubscriptionIOS> _iosProductsById = {};

  // 現在購入フロー中の商品ID -> トライアル希望有無(購入完了イベントに反映するため)
  final Map<String, bool> _pendingTrialFlag = {};

  // finishTransaction の重複呼び出しを避けるための処理済みトークン集合。
  final Set<String> _finishedTransactionKeys = {};

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
      await _iap.initConnection();
      _available = true;
    } catch (_) {
      _available = false;
    }
    if (!_available) return;

    _purchaseSub = _iap.purchaseUpdatedListener.listen(
      _onPurchaseUpdated,
      onError: (Object error) {
        onPendingChanged?.call(false);
        onPurchaseError?.call('購入処理の監視中にエラーが発生したよ: $error');
      },
    );
    _errorSub = _iap.purchaseErrorListener.listen(_onPurchaseError);

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final products = await _iap.fetchProducts<ProductSubscriptionIOS>(
          skus: _productIds,
          type: ProductQueryType.Subs,
        );
        _iosProductsById.clear();
        for (final p in products) {
          _iosProductsById[p.id] = p;
        }
        if (kDebugMode) {
          final missing = _productIds
              .where((id) => !_iosProductsById.containsKey(id))
              .toList();
          if (missing.isNotEmpty) {
            debugPrint(
              'PurchaseService: 見つからなかった商品ID: $missing'
              '(App Store Connect側の商品登録・審査状況を確認してね)',
            );
          }
        }
      } else {
        final products = await _iap.fetchProducts<ProductSubscriptionAndroid>(
          skus: _productIds,
          type: ProductQueryType.Subs,
        );
        _androidProductsById.clear();
        for (final p in products) {
          _androidProductsById[p.id] = p;
        }
        if (kDebugMode) {
          final missing = _productIds
              .where((id) => !_androidProductsById.containsKey(id))
              .toList();
          if (missing.isNotEmpty) {
            debugPrint(
              'PurchaseService: 見つからなかった商品ID: $missing'
              '(Google Play Console側の商品登録・審査状況を確認してね)',
            );
          }
        }
      }
    } catch (e) {
      onPurchaseError?.call('商品情報の取得に失敗したよ: $e');
    }
  }

  /// 指定商品の「価格0円のpricingPhaseを含むオファー」(=無料トライアルオファー)を探す(Android)。
  SubscriptionOffer? _findAndroidOfferWithTrial(String productId) {
    final product = _androidProductsById[productId];
    if (product == null) return null;
    for (final offer in product.subscriptionOffers) {
      final phases = offer.pricingPhasesAndroid?.pricingPhaseList;
      if (phases == null) continue;
      final hasFreePhase = phases.any(
        (p) => (int.tryParse(p.priceAmountMicros) ?? -1) == 0,
      );
      if (hasFreePhase) return offer;
    }
    return null;
  }

  /// 指定商品の「トライアルを含まない通常課金オファー」(base plan)を探す(Android)。
  SubscriptionOffer? _findAndroidBaseOffer(String productId) {
    final product = _androidProductsById[productId];
    if (product == null || product.subscriptionOffers.isEmpty) return null;
    for (final offer in product.subscriptionOffers) {
      final phases = offer.pricingPhasesAndroid?.pricingPhaseList;
      if (phases == null) continue;
      final hasFreePhase = phases.any(
        (p) => (int.tryParse(p.priceAmountMicros) ?? -1) == 0,
      );
      if (!hasFreePhase) return offer;
    }
    // トライアル無しオファーが見つからない場合は先頭を返す(フォールバック)
    return product.subscriptionOffers.first;
  }

  /// 商品情報(価格表示等)を取得済みか。
  bool hasProductInfo(PurchasableProduct product) {
    final id = product.productId;
    return _androidProductsById.containsKey(id) ||
        _iosProductsById.containsKey(id);
  }

  /// 表示用の価格文字列(ストアから取得した実際の価格)。取得前はnull。
  String? formattedPrice(PurchasableProduct product) {
    final id = product.productId;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosProductsById[id]?.displayPrice;
    }
    return _androidProductsById[id]?.displayPrice;
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

    await _buyOnAndroid(productId, withTrial: withTrial);
  }

  /// Android(Google Play Billing)向けの購入フロー。
  Future<void> _buyOnAndroid(
    String productId, {
    required bool withTrial,
  }) async {
    final SubscriptionOffer? chosen = withTrial
        ? (_findAndroidOfferWithTrial(productId) ??
              _findAndroidBaseOffer(productId))
        : _findAndroidBaseOffer(productId);

    if (chosen == null || chosen.offerTokenAndroid == null) {
      onPurchaseError?.call('商品情報が見つからなかったよ。時間をおいて再度試してみてね。');
      return;
    }

    final actuallyTrial =
        withTrial && identical(chosen, _findAndroidOfferWithTrial(productId));
    _pendingTrialFlag[productId] = actuallyTrial;

    try {
      onPendingChanged?.call(true);
      await _iap.requestPurchase(
        RequestPurchaseProps.subs((
          apple: null,
          google: RequestSubscriptionAndroidProps(
            skus: [productId],
            subscriptionOffers: [
              AndroidSubscriptionOfferInput(
                offerToken: chosen.offerTokenAndroid!,
                sku: productId,
              ),
            ],
          ),
        )),
      );
    } catch (e) {
      onPendingChanged?.call(false);
      _pendingTrialFlag.remove(productId);
      onPurchaseError?.call('購入処理を開始できなかったよ: $e');
    }
  }

  /// iOS(App Store / StoreKit)向けの購入フロー。
  /// StoreKitにはAndroidのオファートークンに相当する選択肢が無いため、
  /// 商品IDを指定して購入をリクエストするだけでよい。
  /// Introductory Offer(無料トライアル)の適用有無はApple側が自動判定する。
  Future<void> _buyOnIOS(String productId, {required bool withTrial}) async {
    if (!_iosProductsById.containsKey(productId)) {
      onPurchaseError?.call('商品情報が見つからなかったよ。時間をおいて再度試してみてね。');
      return;
    }

    // ベストエフォートの記録用フラグ(実際の適用有無はApple側の判定次第)。
    _pendingTrialFlag[productId] = withTrial;

    try {
      onPendingChanged?.call(true);
      await _iap.requestPurchase(
        RequestPurchaseProps.subs((
          apple: RequestSubscriptionIosProps(sku: productId),
          google: null,
        )),
      );
    } catch (e) {
      onPendingChanged?.call(false);
      _pendingTrialFlag.remove(productId);
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
      final purchases = await _iap.getAvailablePurchases();
      if (purchases.isEmpty) {
        onPurchaseError?.call('復元できる購入履歴が見つからなかったよ。');
        return;
      }
      for (final purchase in purchases) {
        await _handlePurchase(purchase, isRestore: true);
      }
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

  Future<void> _onPurchaseUpdated(Purchase purchase) async {
    await _handlePurchase(purchase, isRestore: false);
  }

  void _onPurchaseError(PurchaseError error) {
    onPendingChanged?.call(false);
    if (error.productId != null) {
      _pendingTrialFlag.remove(error.productId);
    }
    // ユーザー自身によるキャンセルはエラー表示しない。
    if (error.code == ErrorCode.UserCancelled) {
      return;
    }
    onPurchaseError?.call(error.message);
  }

  Future<void> _handlePurchase(
    Purchase purchase, {
    required bool isRestore,
  }) async {
    // 購入状態が確定していないもの(pending)は完了処理をスキップする。
    if (purchase.purchaseState == PurchaseState.Pending) {
      onPendingChanged?.call(true);
      return;
    }

    onPendingChanged?.call(false);

    final product = _productFromId(purchase.productId);
    if (product != null) {
      final isTrial =
          !isRestore && (_pendingTrialFlag[purchase.productId] ?? false);
      onPurchaseCompleted?.call(
        PurchaseResultEvent(
          product: product,
          isTrial: isTrial,
          isRestore: isRestore,
        ),
      );
    }
    _pendingTrialFlag.remove(purchase.productId);

    // 購入完了処理(Android: acknowledge / iOS: finish)。
    // サブスクリプションは非消費型として扱う。
    final key = purchase.purchaseToken ?? purchase.id;
    if (key.isNotEmpty && _finishedTransactionKeys.contains(key)) {
      return;
    }
    try {
      await _iap.finishTransaction(purchase: purchase, isConsumable: false);
      if (key.isNotEmpty) {
        _finishedTransactionKeys.add(key);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PurchaseService: finishTransaction failed: $e');
      }
    }
  }

  void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
    _errorSub?.cancel();
    _errorSub = null;
    if (_available) {
      _iap.endConnection();
    }
  }
}
