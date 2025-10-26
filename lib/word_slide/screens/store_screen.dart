import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import 'package:word_game_app/services/cosmetic_manager.dart';
import 'package:word_game_app/services/in_app_purchase_service.dart';
import 'package:word_game_app/services/settings_service.dart';
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

class _CosmeticOption {
  final String id;
  final String title;
  final String subtitle;
  final Color? color;
  final Gradient? gradient;
  final IconData icon;

  const _CosmeticOption({
    required this.id,
    required this.title,
    required this.subtitle,
    this.color,
    this.gradient,
    this.icon = Icons.auto_awesome,
  });
}

class _SelectableOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _SelectableOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const _tileSkinOptions = <_CosmeticOption>[
  _CosmeticOption(
    id: 'default',
    title: 'Classic',
    subtitle: 'Match theme colour',
    color: Color(0xFF546E7A),
    icon: Icons.grid_view,
  ),
  _CosmeticOption(
    id: 'wood',
    title: 'Wood Grain',
    subtitle: 'Warm handcrafted tiles',
    color: Color(0xFF8D6E63),
    icon: Icons.park,
  ),
  _CosmeticOption(
    id: 'neon',
    title: 'Neon Pulse',
    subtitle: 'Electric city glow',
    color: Color(0xFF00F5D4),
    icon: Icons.bolt,
  ),
  _CosmeticOption(
    id: 'crystal',
    title: 'Crystal Ice',
    subtitle: 'Cool shimmering finish',
    color: Color(0xFF80DEEA),
    icon: Icons.ac_unit,
  ),
];

const _boardSkinOptions = <_CosmeticOption>[
  _CosmeticOption(
    id: 'classic',
    title: 'Luminous',
    subtitle: 'Default radiant board',
    gradient: LinearGradient(
      colors: [Color(0xFF2F3E5C), Color(0xFF1B253A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    icon: Icons.dashboard_customize,
  ),
  _CosmeticOption(
    id: 'galaxy',
    title: 'Galaxy Drift',
    subtitle: 'Stellar swirl and nebula glow',
    gradient: LinearGradient(
      colors: [Color(0xFF1B2735), Color(0xFF090A0F), Color(0xFF3A1C71)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    icon: Icons.auto_awesome,
  ),
  _CosmeticOption(
    id: 'cyber',
    title: 'Cyber Grid',
    subtitle: 'High-tech holo sheen',
    gradient: LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    icon: Icons.memory,
  ),
];

const _soundPackOptions = <_SelectableOption>[
  _SelectableOption(
    id: 'classic',
    title: 'Classic',
    subtitle: 'Default mix of chimes and clicks',
    icon: Icons.music_note,
  ),
  _SelectableOption(
    id: 'arcade',
    title: 'Arcade',
    subtitle: 'Retro cabinet beeps',
    icon: Icons.gamepad,
  ),
  _SelectableOption(
    id: 'zen',
    title: 'Zen',
    subtitle: 'Soft chimes and ambience',
    icon: Icons.self_improvement,
  ),
];

const _trailOptions = <_SelectableOption>[
  _SelectableOption(
    id: 'sparkle',
    title: 'Sparkle',
    subtitle: 'Bright glitter trail',
    icon: Icons.auto_awesome,
  ),
  _SelectableOption(
    id: 'lightning',
    title: 'Lightning',
    subtitle: 'Crackling energy streak',
    icon: Icons.flash_on,
  ),
  _SelectableOption(
    id: 'aurora',
    title: 'Aurora',
    subtitle: 'Flowing ribbon of light',
    icon: Icons.landscape,
  ),
];

const _freeHintEffectOptions = <_SelectableOption>[
  _SelectableOption(
    id: 'ring',
    title: 'Neon Ring',
    subtitle: 'Cyan halo that pulses around hints',
    icon: Icons.blur_on,
  ),
  _SelectableOption(
    id: 'spotlight',
    title: 'Soft Spotlight',
    subtitle: 'Gentle glow illuminating the tile',
    icon: Icons.highlight,
  ),
];

const _premiumHintEffectOptions = <_SelectableOption>[
  _SelectableOption(
    id: 'arrow-bounce',
    title: 'Arrow Bounce',
    subtitle: 'Animated chevron guiding the next move',
    icon: Icons.double_arrow,
  ),
];

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
    final cosmetics = context.watch<CosmeticManager>();
    final settings = context.watch<SettingsService>();


    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customization Store'),
          actions: [
            TextButton(
              onPressed: service.restorePurchases,
              child:
              const Text('Restore', style: TextStyle(color: Colors.white)),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.color_lens_outlined),
                text: 'Cosmetics',
              ),
              Tab(
                icon: Icon(Icons.stars_outlined),
                text: 'Premium',
              ),
            ],
          ),
        ),
        body: FutureBuilder<List<ProductDetails>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const TabBarView(
                children: [
                  Center(child: CircularProgressIndicator()),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            final products = {
              for (final p in snapshot.data ?? <ProductDetails>[]) p.id: p
            };

            return TabBarView(
              children: [
                _buildCosmeticsTab(context, cosmetics, settings),
                _buildPremiumTab(context, service, cosmetics, products, settings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCosmeticsTab(
      BuildContext context,
      CosmeticManager cosmetics,
      SettingsService settings,
      ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StoreSectionCard(
          title: 'Tile Skins',
          subtitle: 'Swap the base texture and material of each tile.',
          child: _CosmeticChoiceGrid(
            options: _tileSkinOptions,
            selectedId: cosmetics.tileSkin,
            onSelected: (id) => cosmetics.setSkin('tile', id),
          ),
        ),
        const SizedBox(height: 16),
        _StoreSectionCard(
          title: 'Board Themes',
          subtitle: 'Change the mood of the playfield background.',
          child: _CosmeticChoiceGrid(
            options: _boardSkinOptions,
            selectedId: cosmetics.boardSkin,
            onSelected: (id) => cosmetics.setSkin('board', id),
          ),
        ),
        const SizedBox(height: 16),
        _StoreSectionCard(
          title: 'Sound Packs',
          subtitle: 'Pick the soundtrack for moves and celebrations.',
          child: _SelectableList(
            options: _soundPackOptions,
            selectedId: settings.soundPack,
            onChanged: (id) {
              cosmetics.setSkin('sound', id);
              unawaited(settings.updateSoundPack(id));
            },
          ),
        ),
        const SizedBox(height: 16),
        _StoreSectionCard(
          title: 'Word Trail Effects',
          subtitle: 'Customize the particle trail that follows solved words.',
          child: _SelectableList(
            options: _trailOptions,
            selectedId: cosmetics.trailEffect,
            onChanged: (id) => cosmetics.setSkin('trail', id),
          ),
        ),
        const SizedBox(height: 16),
        _StoreSectionCard(
          title: 'Hint Effects',
          subtitle: 'Decide how free hints glow on the puzzle board.',
          child: _SelectableList(
            options: _freeHintEffectOptions,
            selectedId: settings.hintEffect,
            onChanged: (id) {
              cosmetics.setSkin('hint', id);
              unawaited(settings.updateHintEffect(id));
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPremiumTab(
      BuildContext context,
      InAppPurchaseService service,
      CosmeticManager cosmetics,
      Map<String, ProductDetails> products,
      SettingsService settings,
      ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _StoreSectionCard(
          title: 'Coins & Premium',
          subtitle: 'Top up hints or unlock premium bundles and rewards.',
          child: _MonetizationRow(),
        ),
        const SizedBox(height: 16),
        _StoreSectionCard(
          title: 'Premium Borders',
          subtitle: 'Luxurious frames that wrap each tile.',
          child: _StoreGrid(
            itemCount: _borders.length,
            itemBuilder: (context, index) {
              final border = _borders[index];
              final owned = service.isProductPurchased(border.id) ||
                  (kDebugMode && settings.devUnlockPremiumCosmetics);
              final product = products[border.id];
              return _StoreProductCard(
                preview: _BorderPreview(border: border),
                title: border.style.displayName,
                subtitle: 'Border style',
                owned: owned,
                product: product,
                onTap:
                product == null ? null : () => service.buy(product),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _StoreSectionCard(
          title: 'Premium Animations',
          subtitle: 'Give tiles unique entrances and idle motion.',
          child: _StoreGrid(
            itemCount: _animations.length,
            itemBuilder: (context, index) {
              final animation = _animations[index];
              final owned = service.isProductPurchased(animation.id) ||
                  (kDebugMode && settings.devUnlockPremiumCosmetics);
              final product = products[animation.id];
              return _StoreProductCard(
                preview: _AnimationPreview(product: animation),
                title: animation.style.displayName,
                subtitle: animation.style.description,
                owned: owned,
                product: product,
                onTap:
                product == null ? null : () => service.buy(product),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _StoreSectionCard(
          title: 'Premium Hint Effects',
          subtitle:
          'Unlock the animated arrow bounce guidance.',
          child: _SelectableList(
            options: _premiumHintEffectOptions,
            selectedId: settings.hintEffect,
            onChanged: (id) {
              cosmetics.setSkin('hint', id);
              unawaited(settings.updateHintEffect(id));
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StoreSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _StoreSectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: subtitleStyle),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
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

class _CosmeticChoiceGrid extends StatelessWidget {
  final List<_CosmeticOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _CosmeticChoiceGrid({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final selected = option.id == selectedId;
        final baseColor = selected
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surface;
        return Material(
          color: baseColor,
          elevation: selected ? 6 : 2,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onSelected(option.id),
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 140,
              height: 140,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: option.gradient == null
                            ? option.color
                            : null,
                        gradient: option.gradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: option.gradient == null
                          ? Icon(option.icon,
                          color: Colors.white.withOpacity(0.9))
                          : Icon(option.icon,
                          color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      option.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SelectableList extends StatelessWidget {
  final List<_SelectableOption> options;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _SelectableList({
    required this.options,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        return Card(
          child: RadioListTile<String>(
            value: option.id,
            groupValue: selectedId,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
            title: Text(option.title),
            subtitle: Text(option.subtitle),
            secondary: Icon(option.icon),
          ),
        );
      }).toList(),
    );
  }
}

class _MonetizationRow extends StatelessWidget {
  const _MonetizationRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 36),
                  const SizedBox(height: 12),
                  const Text('Coin Bundles'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('In-app coin purchases coming soon!'),
                        ),
                      );
                    },
                    child: const Text('Coming soon'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_fill, size: 36),
                  const SizedBox(height: 12),
                  const Text('Rewarded Ads'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Watch-to-earn rewards are on the roadmap.'),
                        ),
                      );
                    },
                    child: const Text('Stay tuned'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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