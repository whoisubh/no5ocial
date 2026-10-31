import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Central Google Play Billing and App Store in-app purchase service.
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

  /// Processes updates received on the purchase stream.
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('PlayBillingService: Purchase pending for ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('PlayBillingService: Purchase failed for ${purchase.productID}: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        debugPrint('PlayBillingService: Purchase verified for ${purchase.productID}');
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
