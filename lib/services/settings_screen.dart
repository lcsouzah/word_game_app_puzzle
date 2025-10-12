import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_game_app/services/in_app_purchase_service.dart';
import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/word_slide/models/board_style.dart';
import 'package:word_game_app/word_slide/models/tile_animation_style.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';
import 'package:word_game_app/word_slide/screens/store_screen.dart';

const _availableTileColors = <Color>[
  Colors.blueGrey, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.brown, Colors.indigo,
  Colors.lightBlue, Colors.pink, Colors.yellow, Colors.cyan, Colors.lime, Colors.amber, Colors.deepOrange,
  Colors.deepPurple, Colors.grey, Colors.lightGreen, Colors.deepPurpleAccent, Colors.pinkAccent,
  Color(0xFF7E57C2), // Deep lavender
  Color(0xFF4CAF50), // Balanced emerald
];

const _availableBorderColors = <Color>[
  Colors.blueGrey, Colors.white, Colors.white60, Colors.amber, Colors.deepPurpleAccent, Colors.pinkAccent, Colors.black87,
  Colors.cyanAccent, Colors.redAccent, Colors.greenAccent, Colors.yellowAccent, Colors.blueAccent, Colors.orangeAccent,
  Colors.purpleAccent, Colors.tealAccent, Colors.brown, Colors.indigo, Colors.lightBlue, Colors.pink, Colors.yellow,
  Color(0xFFFFF59D), // Soft gold
  Color(0xFFB0BEC5), // Frosted steel

];

/// Screen allowing the player to customise tile colour and border image.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final purchaseService = context.watch<InAppPurchaseService>();

    final selectedAnimationStyle = settings.tileAnimationStyle;
    final freeStyles = TileBorderStyles.freeStyles.toList();
    final premiumStyles = TileBorderStyles.premiumStyles.toList();
    final freeBoardStyles = BoardStyles.freeStyles.toList();
    final premiumBoardStyles = BoardStyles.premiumStyles.toList();
    final freeAnimationStyles = TileAnimationStyles.freeStyles.toList();
    final premiumAnimationStyles = TileAnimationStyles.premiumStyles.toList();
    final purchasedProductIds = purchaseService.purchasedProductIds;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Sound Effects'),
                  subtitle: const Text('Enable taps and celebration sounds'),
                  value: settings.soundEnabled,
                  onChanged: (value) =>
                      unawaited(settings.updateSoundEnabled(value)),
                ),
                SwitchListTile(
                  title: const Text('Haptic Feedback'),
                  subtitle:
                  const Text('Vibrate on tile moves and completed words'),
                  value: settings.hapticsEnabled,
                  onChanged: (value) =>
                      unawaited(settings.updateHapticsEnabled(value)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tile Colour',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _TileColorPalette(
            colors: _availableTileColors,
            selectedColor: settings.tileColor,
            onColorSelected: settings.updateTileColor,
          ),
          const SizedBox(height: 24),

          const Text(
            'Border Colour',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _TileColorPalette(
            colors: _availableBorderColors,
            selectedColor: settings.borderColor,
            onColorSelected: settings.updateBorderColor,
          ),

          const SizedBox(height: 24),
          const Text(
            'Free Borders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _StyleGrid(
            styles: freeStyles,
            selectedStyleId: settings.borderStyle.id,
            tileColor: settings.tileColor,
            borderColor: settings.borderColor,
            purchasedBorderIds: purchasedProductIds,
            onStyleSelected: (style) =>
                unawaited(settings.updateBorderStyle(style, allowPremium: true)),
            onLockedTap: (style) => _openStore(context),
          ),
          if (premiumStyles.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Premium Borders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _StyleGrid(
              styles: premiumStyles,
              selectedStyleId: settings.borderStyle.id,
              tileColor: settings.tileColor,
              borderColor: settings.borderColor,
              purchasedBorderIds: purchasedProductIds,
              onStyleSelected: (style) => unawaited(
                settings.updateBorderStyle(
                  style,
                  allowPremium:
                  !style.isPremium || purchasedProductIds.contains(style.id),
                ),
              ),
              onLockedTap: (style) => _handleLockedStyleTap(context, style),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Board Styles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _BoardStyleGrid(
            styles: freeBoardStyles,
            selectedStyleId: settings.boardStyle.id,
            purchasedProductIds: purchasedProductIds,
            onStyleSelected: (style) => unawaited(
              settings.updateBoardStyle(style, allowPremium: true),
            ),
            onLockedTap: (style) => _openStore(context),
          ),
          if (premiumBoardStyles.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Premium Boards',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _BoardStyleGrid(
              styles: premiumBoardStyles,
              selectedStyleId: settings.boardStyle.id,
              purchasedProductIds: purchasedProductIds,
              onStyleSelected: (style) => unawaited(
                settings.updateBoardStyle(
                  style,
                  allowPremium: !style.isPremium ||
                      purchasedProductIds.contains(style.id),
                ),
              ),
              onLockedTap: (style) => _handleLockedBoardStyleTap(context, style),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Tile Animations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _TileAnimationGrid(
            styles: freeAnimationStyles,
            selectedStyleId: selectedAnimationStyle.id,
            purchasedProductIds: purchasedProductIds,
            onStyleSelected: (style) => unawaited(
              settings.updateTileAnimationStyle(
                style,
                allowPremium: true,
              ),
            ),
            onLockedTap: (style) => _openStore(context),
          ),
          if (premiumAnimationStyles.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Premium Animations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _TileAnimationGrid(
              styles: premiumAnimationStyles,
              selectedStyleId: selectedAnimationStyle.id,
              purchasedProductIds: purchasedProductIds,
              onStyleSelected: (style) => unawaited(
                settings.updateTileAnimationStyle(
                  style,
                  allowPremium:
                  !style.isPremium || purchasedProductIds.contains(style.id),
                ),
              ),
              onLockedTap: (style) =>
                  _handleLockedAnimationStyleTap(context, style),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('Border Store'),
              subtitle: const Text('Browse and unlock new border styles'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoreScreenProvider(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void _handleLockedStyleTap(BuildContext context, TileBorderStyle style) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${style.displayName} is a premium border. Visit the store to unlock it.'),
        action: SnackBarAction(
          label: 'Store',
          onPressed: () => _openStore(context),
        ),
      ),
    );
  }

  void _handleLockedBoardStyleTap(BuildContext context, BoardStyle style) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${style.displayName} is a premium board. Visit the store to unlock it.'),
        action: SnackBarAction(
          label: 'Store',
          onPressed: () => _openStore(context),
        ),
      ),
    );
  }

  void _handleLockedAnimationStyleTap(
      BuildContext context, TileAnimationStyle style) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${style.displayName} is a premium animation. Visit the store to unlock it.'),
        action: SnackBarAction(
          label: 'Store',
          onPressed: () => _openStore(context),
        ),
      ),
    );
  }

  void _openStore(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StoreScreenProvider(),
      ),
    );
  }
}

class _TileColorPalette extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final Future<void> Function(Color color) onColorSelected;

  const _TileColorPalette({
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in colors)
          _TileColorSwatch(
            color: color,
            isSelected: color == selectedColor,
            onTap: () {
              unawaited(onColorSelected(color));
            },
          ),
      ],
    );
  }
}

class _TileColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TileColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlightColor = Theme.of(context).colorScheme.secondary;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? highlightColor : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: highlightColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: AnimatedOpacity(
            opacity: isSelected ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _TilePreview extends StatelessWidget {
  final TileBorderStyle style;
  final Color tileColor;
  final Color borderColor;
  final TileBorderDecoration? decorationOverride;

  const _TilePreview({
    required this.style,
    required this.tileColor,
    required this.borderColor,
    this.decorationOverride,
  });

  @override
  Widget build(BuildContext context) {
    final styleDecoration = decorationOverride ?? style.buildDecoration(
      tileColor: tileColor,
      borderColor: borderColor,
      highlighted: false,
    );
    final boxDecoration = BoxDecoration(
      color: styleDecoration.gradient == null
          ? styleDecoration.fillColor ?? tileColor
          : null,
      gradient: styleDecoration.gradient,
      borderRadius:
      styleDecoration.borderRadius ?? BorderRadius.circular(8),
      border: styleDecoration.border,
      boxShadow: styleDecoration.boxShadows,
    );

    return Container(
      width: 60,
      height: 60,
      decoration: boxDecoration,
      foregroundDecoration: styleDecoration.foregroundDecoration,
      alignment: Alignment.center,
      child: const Text(
        'A',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _BoardStyleGrid extends StatelessWidget {
  final List<BoardStyle> styles;
  final String selectedStyleId;
  final Set<String> purchasedProductIds;
  final void Function(BoardStyle style) onStyleSelected;
  final void Function(BoardStyle style) onLockedTap;

  const _BoardStyleGrid({
    required this.styles,
    required this.selectedStyleId,
    required this.purchasedProductIds,
    required this.onStyleSelected,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    if (styles.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final style = styles[index];
        final isLocked = style.isPremium && !purchasedProductIds.contains(style.id);
        final isSelected = selectedStyleId == style.id;

        final decoration = style.buildDecoration(
          BoardStyleContext(theme: Theme.of(context)),
        );

        return _BoardStyleChip(
          style: style,
          decoration: decoration,
          isLocked: isLocked,
          isSelected: isSelected,
          onTap: isLocked ? () => onLockedTap(style) : () => onStyleSelected(style),
        );
      },
    );
  }
}

class _BoardStyleChip extends StatelessWidget {
  final BoardStyle style;
  final BoardStyleDecoration decoration;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

  const _BoardStyleChip({
    required this.style,
    required this.decoration,
    required this.isLocked,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlightColor = Theme.of(context).colorScheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: decoration.borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: decoration.borderRadius,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: decoration.borderRadius,
                    border: Border.all(
                      color: isSelected ? highlightColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: _BoardStylePreview(decoration: decoration),
                ),
                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: decoration.borderRadius,
                        color: Colors.black45,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          style.displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _BoardStylePreview extends StatelessWidget {
  final BoardStyleDecoration decoration;

  const _BoardStylePreview({required this.decoration});

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: decoration.backgroundColor,
      gradient: decoration.backgroundGradient,
      borderRadius: decoration.borderRadius,
      border: decoration.border,
      boxShadow: decoration.boxShadows,
      image: decoration.backgroundImage,
    );

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: boxDecoration,
        child: ClipRRect(
          borderRadius: decoration.borderRadius,
          child: Container(
            padding: decoration.padding,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.contain,
              child: const _BoardPreviewTiles(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPreviewTiles extends StatelessWidget {
  const _BoardPreviewTiles();

  @override
  Widget build(BuildContext context) {
    const int dimension = 4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < dimension; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int col = 0; col < dimension; col++)
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 0.6,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _StyleGrid extends StatelessWidget {
  final List<TileBorderStyle> styles;
  final String selectedStyleId;
  final Color tileColor;
  final Color borderColor;
  final Set<String> purchasedBorderIds;
  final void Function(TileBorderStyle style) onStyleSelected;
  final void Function(TileBorderStyle style) onLockedTap;

  const _StyleGrid({
    required this.styles,
    required this.selectedStyleId,
    required this.tileColor,
    required this.borderColor,
    required this.purchasedBorderIds,
    required this.onStyleSelected,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    if (styles.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final style = styles[index];
        final decoration = style.buildDecoration(
          tileColor: tileColor,
          borderColor: borderColor,
          highlighted: false,
        );
        final isLocked =
            style.isPremium && !purchasedBorderIds.contains(style.id);
        final isSelected = selectedStyleId == style.id;

        return _StyleChip(
          style: style,
          decoration: decoration,
          tileColor: tileColor,
          borderColor: borderColor,
          isLocked: isLocked,
          isSelected: isSelected,
          onTap: isLocked
              ? () => onLockedTap(style)
              : () => onStyleSelected(style),
        );
      },
    );
  }
}

class _StyleChip extends StatelessWidget {
  final TileBorderStyle style;
  final TileBorderDecoration decoration;
  final Color tileColor;
  final Color borderColor;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyleChip({
    required this.style,
    required this.decoration,
    required this.tileColor,
    required this.borderColor,
    required this.isLocked,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final previewRadius = decoration.borderRadius ?? BorderRadius.circular(8);
    final highlightColor = Theme.of(context).colorScheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: previewRadius,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: previewRadius,
                    border: Border.all(
                      color: isSelected ? highlightColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: _TilePreview(
                    style: style,
                    tileColor: tileColor,
                    borderColor: borderColor,
                    decorationOverride: decoration,
                  ),
                ),
                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: previewRadius,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          style.displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TileAnimationGrid extends StatelessWidget {
  final List<TileAnimationStyle> styles;
  final String selectedStyleId;
  final Set<String> purchasedProductIds;
  final void Function(TileAnimationStyle style) onStyleSelected;
  final void Function(TileAnimationStyle style) onLockedTap;

  const _TileAnimationGrid({
    required this.styles,
    required this.selectedStyleId,
    required this.purchasedProductIds,
    required this.onStyleSelected,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    if (styles.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final style = styles[index];
        final isLocked =
            style.isPremium && !purchasedProductIds.contains(style.id);
        final isSelected = selectedStyleId == style.id;

        return _TileAnimationChip(
          style: style,
          isLocked: isLocked,
          isSelected: isSelected,
          onTap:
          isLocked ? () => onLockedTap(style) : () => onStyleSelected(style),
        );
      },
    );
  }
}

class _TileAnimationChip extends StatelessWidget {
  final TileAnimationStyle style;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

  const _TileAnimationChip({
    required this.style,
    required this.isLocked,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.secondary;
    final borderColor = isSelected
        ? highlightColor
        : theme.dividerColor.withOpacity(0.6);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.4 : 1.2,
            ),
            color: theme.cardColor.withOpacity(isSelected ? 0.9 : 0.8),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: highlightColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(style.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      style.displayName,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLocked)
                    const Icon(
                      Icons.lock,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  style.description,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}