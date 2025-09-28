import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_game_app/services/in_app_purchase_service.dart';
import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';
import 'package:word_game_app/word_slide/screens/store_screen.dart';

const _availableTileColors = <Color>[
  Colors.blueGrey,
  Colors.red,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.brown,
  Colors.indigo,
  Colors.lightBlue,
  Colors.pink,
  Colors.yellow,
  Colors.cyan,
  Colors.lime,
  Colors.amber,
  Colors.deepOrange,
  Colors.deepPurple,
  Colors.grey,
  Colors.lightGreen,
  Colors.deepPurpleAccent,
  Colors.pinkAccent,
  Color(0xFF7E57C2), // Deep lavender
  Color(0xFF4CAF50), // Balanced emerald
];

const _availableBorderColors = <Color>[
  Colors.blueGrey,
  Colors.white,
  Colors.white60,
  Colors.amber,
  Colors.deepPurpleAccent,
  Colors.pinkAccent,
  Colors.black87,
  Colors.cyanAccent,
  Colors.redAccent,
  Colors.greenAccent,
  Colors.yellowAccent,
  Colors.blueAccent,
  Colors.orangeAccent,
  Colors.purpleAccent,
  Colors.tealAccent,
  Colors.brown,
  Colors.indigo,
  Colors.lightBlue,
  Colors.pink,
  Colors.yellow,
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

    final freeStyles = TileBorderStyles.freeStyles.toList();
    final premiumStyles = TileBorderStyles.premiumStyles.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            purchasedBorderIds: purchaseService.purchasedBorderIds,
            onStyleSelected: settings.updateBorderStyle,
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
              purchasedBorderIds: purchaseService.purchasedBorderIds,
              onStyleSelected: settings.updateBorderStyle,
              onLockedTap: (style) => _handleLockedStyleTap(context, style),
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