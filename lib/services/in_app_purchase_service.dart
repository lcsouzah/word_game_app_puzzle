import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that wraps the [in_app_purchase] plugin and keeps track of
/// purchased border identifiers. Purchased IDs are persisted using
/// [SharedPreferences] so that the app can later display only the borders
/// owned by the user in the settings screen.
class InAppPurchaseService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  static const _prefsProductsKey = 'purchased_products';
  static const _legacyBorderKey = 'purchased_borders';

  final Set<String> _purchasedProductIds = <String>{};
  bool _available = false;

  /// Returns whether the underlying store is available.
  bool get isAvailable => _available;

  /// Returns a read only view of the purchased product IDs.
  Set<String> get purchasedProductIds => _purchasedProductIds;

  /// Convenience getter preserved for border specific checks.
  Set<String> get purchasedBorderIds => _purchasedProductIds;

  /// Returns whether the provided [productId] has been purchased.
  bool isProductPurchased(String productId) =>
      _purchasedProductIds.contains(productId);

  /// Initializes the connection to the store and loads any previously
  /// purchased border IDs from storage. This should be called once when the
  /// application launches or when the store screen is opened.
  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    await _loadPurchasedIds();

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription.cancel(),
      onError: (Object _) {},
    );

    notifyListeners();
  }

  /// Queries product details for the provided [ids].
  Future<List<ProductDetails>> loadProducts(List<String> ids) async {
    final response = await _iap.queryProductDetails(ids.toSet());
    return response.productDetails;
  }

  /// Initiates the purchase flow for a non‑consumable product.
  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restores previously purchased products from the store.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _loadPurchasedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final storedProducts = prefs.getStringList(_prefsProductsKey);
    if (storedProducts != null) {
      _purchasedProductIds.addAll(storedProducts);
      return;
    }

    // Legacy migration path from when we only tracked borders.
    final legacyBorders = prefs.getStringList(_legacyBorderKey);
    if (legacyBorders != null && legacyBorders.isNotEmpty) {
      _purchasedProductIds.addAll(legacyBorders);
      await prefs.setStringList(
        _prefsProductsKey,
        _purchasedProductIds.toList(),
      );
      await prefs.remove(_legacyBorderKey);
    }
  }

  Future<void> _savePurchasedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsProductsKey,
      _purchasedProductIds.toList(),
    );
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _purchasedProductIds.add(purchase.productID);
        await _savePurchasedIds();
        await _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
