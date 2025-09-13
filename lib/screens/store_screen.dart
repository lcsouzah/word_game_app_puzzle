import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../services/in_app_purchase_service.dart';

/// Simple data class that describes a border product available for purchase.
class BorderProduct {
  final String id;
  final String assetPath;

  const BorderProduct({required this.id, required this.assetPath});
}

/// Screen that displays the available borders and allows the user to purchase
/// or restore them. Purchased borders are marked with a check icon while
/// locked borders are dimmed with a lock icon overlay.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  StoreScreenState createState() => StoreScreenState();
}

class StoreScreenState extends State<StoreScreen> {
  // Example border products. The images should exist in the assets folder and
  // correspond to the product identifiers in the store.
  final List<BorderProduct> _borders = const [
    BorderProduct(id: 'border_gold', assetPath: 'assets/images/borders/gold.png'),
    BorderProduct(id: 'border_silver', assetPath: 'assets/images/borders/silver.png'),
    BorderProduct(id: 'border_bronze', assetPath: 'assets/images/borders/bronze.png'),
  ];

  late Future<List<ProductDetails>> _productsFuture;

  @override
  void initState() {
    super.initState();
    final service = context.read<InAppPurchaseService>();
    _productsFuture = service.loadProducts(_borders.map((b) => b.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<InAppPurchaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Border Store'),
        actions: [
          TextButton(
            onPressed: service.restorePurchases,
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: FutureBuilder<List<ProductDetails>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = {
            for (final p in snapshot.data ?? <ProductDetails>[]) p.id: p
          };

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: _borders.length,
            itemBuilder: (context, index) {
              final border = _borders[index];
              final owned = service.purchasedBorderIds.contains(border.id);
              final product = products[border.id];

              return GestureDetector(
                onTap: owned || product == null
                    ? null
                    : () => service.buy(product),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(border.assetPath, fit: BoxFit.cover),
                      ),
                    ),
                    if (!owned)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: Icon(
                              product == null ? Icons.block : Icons.lock,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    if (owned)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.check_circle, color: Colors.greenAccent),
                      )
                    else if (product != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          color: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            product.price,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Helper widget that provides the [InAppPurchaseService] for the [StoreScreen].
/// This can be used when navigating to the store if no provider exists higher
/// in the widget tree.
class StoreScreenProvider extends StatelessWidget {
  const StoreScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InAppPurchaseService()..initialize(),
      child: const StoreScreen(),
    );
  }
}
