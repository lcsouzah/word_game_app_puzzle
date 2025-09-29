import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import 'package:word_game_app/services/in_app_purchase_service.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';

/// Simple data class that describes a border product available for purchase.
class BorderProduct {
  final String styleId;
  final Color previewTileColor;
  final Color previewBorderColor;

  const BorderProduct({
    required this.styleId,
    required this.previewTileColor,
    required this.previewBorderColor,
  });

  String get id => styleId;

  TileBorderStyle get style => TileBorderStyles.byId(styleId);
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
  // Premium border products backed by TileBorderStyle identifiers so the
  // preview matches the in-game appearance.
  final List<BorderProduct> _borders = const [
    BorderProduct(
      styleId: 'gold_gloss',
      previewTileColor: const Color(0xFF2B2D42),
      previewBorderColor: const Color(0xFFFFD700),
    ),
    BorderProduct(
      styleId: 'silver_glow',
      previewTileColor: const Color(0xFF1F2933),
      previewBorderColor: const Color(0xFFCFD8DC),
    ),
    BorderProduct(
      styleId: 'bronze_edge',
      previewTileColor: const Color(0xFF3A2D21),
      previewBorderColor: const Color(0xFFCC7A00),
    ),
    BorderProduct(
      styleId: 'neon_glow',
      previewTileColor: const Color(0xFF141021),
      previewBorderColor: const Color(0xFF4CC9F0),
    ),
    BorderProduct(
      styleId: 'lava_edge',
      previewTileColor: const Color(0xFF2C1000),
      previewBorderColor: const Color(0xFFFF6D00),
    ),
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
                  clipBehavior: Clip.none,
                  children: [
                    _BorderPreview(border: border),
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

class _BorderPreview extends StatelessWidget {
  final BorderProduct border;

  const _BorderPreview({required this.border});

  @override
  Widget build(BuildContext context) {
    final decoration = border.style.buildDecoration(
      tileColor: border.previewTileColor,
      borderColor: border.previewBorderColor,
      highlighted: true,
    );
    final borderRadius = decoration.borderRadius ?? BorderRadius.circular(12);

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: decoration.gradient,
          border: decoration.border,
          boxShadow: decoration.boxShadows,
          color: decoration.fillColor ?? Colors.transparent,
        ),
        foregroundDecoration: decoration.foregroundDecoration,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Container(color: border.previewTileColor),
          ),
        ),
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
