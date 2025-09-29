import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import 'package:word_game_app/services/in_app_purchase_service.dart';
import 'package:word_game_app/word_slide/models/tile_animation_style.dart';
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

/// Simple data class that describes a premium animation product.
class AnimationProduct {
  final TileAnimationStyle style;
  final Color backgroundColor;
  final Color iconColor;

  const AnimationProduct({
    required this.style,
    required this.backgroundColor,
    required this.iconColor,
  });

  String get id => style.id;
}

/// Screen that displays the available borders and animation styles and allows
/// the user to purchase or restore them. Purchased items are marked with a
/// check icon while locked ones are dimmed with a lock icon overlay.
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

  late final List<AnimationProduct> _animations;

  late Future<List<ProductDetails>> _productsFuture;

  @override
  void initState() {
    super.initState();
    final service = context.read<InAppPurchaseService>();
    _animations = TileAnimationStyles.premiumStyles
        .map(
          (style) => AnimationProduct(
        style: style,
        backgroundColor: switch (style.id) {
          'anim_teleport' => const Color(0xFF112031),
          'anim_puff' => const Color(0xFF2B1620),
          _ => const Color(0xFF1C1C1C),
        },
        iconColor: switch (style.id) {
          'anim_teleport' => const Color(0xFF64FFDA),
          'anim_puff' => const Color(0xFFFFB4A2),
          _ => Colors.white,
        },
      ),
    )
        .toList(growable: false);
    final productIds = <String>{
      for (final border in _borders) border.id,
      for (final animation in _animations) animation.id,
    };
    _productsFuture = service.loadProducts(productIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<InAppPurchaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customization Store'),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionHeader(title: 'Premium Borders'),
              const SizedBox(height: 12),
              _StoreGrid(
                itemCount: _borders.length,
                itemBuilder: (context, index) {
                  final border = _borders[index];
                  final owned = service.isProductPurchased(border.id);
                  final product = products[border.id];
                  return _StoreProductCard(
                    preview: _BorderPreview(border: border),
                    title: border.style.displayName,
                    subtitle: 'Border style',
                    owned: owned,
                    product: product,
                    onTap: product == null
                        ? null
                        : () => service.buy(product),
                  );
                },
              ),
              const SizedBox(height: 32),
              const _SectionHeader(title: 'Premium Animations'),
              const SizedBox(height: 12),
              _StoreGrid(
                itemCount: _animations.length,
                itemBuilder: (context, index) {
                  final animation = _animations[index];
                  final owned = service.isProductPurchased(animation.id);
                  final product = products[animation.id];
                  return _StoreProductCard(
                    preview: _AnimationPreview(product: animation),
                    title: animation.style.displayName,
                    subtitle: animation.style.description,
                    owned: owned,
                    product: product,
                    onTap: product == null
                        ? null
                        : () => service.buy(product),
                  );
                },
              ),
            ],
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

    return Container(
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
    );
  }
}

class _AnimationPreview extends StatelessWidget {
  final AnimationProduct product;

  const _AnimationPreview({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            product.backgroundColor,
            Color.alphaBlend(Colors.white10, product.backgroundColor),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          product.style.icon,
          size: 52,
          color: product.iconColor,
        ),
      ),
    );
  }
}

class _StoreGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const _StoreGrid({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class _StoreProductCard extends StatelessWidget {
  final Widget preview;
  final String title;
  final String? subtitle;
  final bool owned;
  final ProductDetails? product;
  final VoidCallback? onTap;

  const _StoreProductCard({
    required this.preview,
    required this.title,
    this.subtitle,
    required this.owned,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(16);
    final price = product?.price;

    return GestureDetector(
      onTap: owned || product == null || onTap == null ? null : onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: borderRadius,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: preview,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (!owned)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Container(
                  color: Colors.black45,
                  child: Center(
                    child: Icon(
                      product == null ? Icons.block : Icons.lock,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          if (owned)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            )
          else if (price != null)
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  price,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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