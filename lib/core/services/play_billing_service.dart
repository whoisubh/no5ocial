import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/services/session_service.dart';
import 'package:no5ocial/core/services/fcm_notification_service.dart';
import 'package:no5ocial/core/services/firebase_analytics_service.dart';

/// Central Google Play Billing and App Store in-app purchase service.
/// Connects verified Google Play store purchases directly to real workspace entitlements and coin wallet.
class PlayBillingService extends ChangeNotifier {
  PlayBillingService._();
  static final PlayBillingService instance = PlayBillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _isLoading = false;

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;

  // Registered Google Play Product Identifiers
  static const Set<String> _productIds = {
    'solo_pro_monthly',
    'b2b_team_monthly',
    'coin_pack_50',
    'coin_pack_120',
  };

  /// Initializes the in-app purchase client and purchase stream listener.
  Future<void> init() async {
    if (kIsWeb) return;

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        debugPrint('PlayBillingService: Google Play Billing is unavailable on this device.');
        return;
      }

      _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (err) => debugPrint('PlayBillingService: Purchase stream error: $err'),
      );

      await loadProducts();
      debugPrint('PlayBillingService: Google Play Billing initialized successfully.');
    } catch (e) {
      debugPrint('PlayBillingService: Warning initializing billing client: $e');
    }
  }

  /// Fetches available products and subscriptions from Google Play.
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('PlayBillingService: Product query error: ${response.error}');
      }
      _products = response.productDetails;
    } catch (e) {
      debugPrint('PlayBillingService: Error querying products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initiates a purchase flow for a specific product.
  Future<bool> buyProduct(ProductDetails product, {bool isConsumable = false}) async {
    if (!_isAvailable) return false;

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      if (isConsumable) {
        return await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      debugPrint('PlayBillingService: Error initiating purchase for ${product.id}: $e');
      return false;
    }
  }

  /// Restores previous purchases (e.g. for reinstalled apps or subscriptions).
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('PlayBillingService: Error restoring purchases: $e');
    }
  }

  /// Processes updates received on the purchase stream and fulfills entitlements.
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('PlayBillingService: Purchase pending for ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('PlayBillingService: Purchase failed for ${purchase.productID}: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        debugPrint('PlayBillingService: Fulfilling entitlement for ${purchase.productID}');
        await _deliverProductEntitlement(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  /// Delivers verified in-app goods directly to user balance
  Future<void> _deliverProductEntitlement(PurchaseDetails purchase) async {
    try {
      final session = await SessionService.instance.getSession();
      final uid = session?['id'] as String? ?? 'local_user';
      final pid = purchase.productID;

      int coinsToCredit = 0;
      String description = 'Google Play In-App Purchase ($pid)';

      if (pid == 'coin_pack_50') {
        coinsToCredit = 50;
        description = 'Google Play: 50 Coin Pack';
      } else if (pid == 'coin_pack_120') {
        coinsToCredit = 120;
        description = 'Google Play: 120 Coin Pack';
      } else if (pid == 'solo_pro_monthly') {
        coinsToCredit = 100;
        description = 'Google Play: Solo Pro Monthly Plan (100 Coins Bonus)';
      } else if (pid == 'b2b_team_monthly') {
        coinsToCredit = 300;
        description = 'Google Play: Team Business Monthly Plan (300 Coins Bonus)';
      }

      if (coinsToCredit > 0) {
        await MonetizationService.instance.addCoins(
          coinsToCredit,
          userId: uid,
          description: description,
        );

        unawaited(FcmNotificationService.instance.showNotification(
          id: 7770 + coinsToCredit,
          title: 'Purchase Successful! 🪙',
          body: '+$coinsToCredit Coins deposited into your workspace wallet.',
          payload: '{"screen": "wallet"}',
        ));

        unawaited(FirebaseAnalyticsService.instance.logCoinsEarned(
          type: 'google_play_purchase',
          amount: coinsToCredit,
        ));
      }
    } catch (e) {
      debugPrint('PlayBillingService: Error delivering product entitlement: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
