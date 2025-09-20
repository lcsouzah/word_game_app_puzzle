import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_game_app/services/in_app_purchase_service.dart';
import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';
import 'package:word_game_app/word_slide/screens/store_screen.dart';

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
            'Free Borders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _StyleGrid(
            styles: freeStyles,
            selectedStyleId: settings.borderStyle.id,
            tileColor: settings.tileColor,
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

class _TilePreview extends StatelessWidget {
  final TileBorderStyle style;
  final Color tileColor;
  final TileBorderDecoration? decorationOverride;

  const _TilePreview({
    required this.style,
    required this.tileColor,
    this.decorationOverride,
  });

  @override
  Widget build(BuildContext context) {
    final styleDecoration = decorationOverride ?? style.buildDecoration(
      tileColor: tileColor,
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
  final Set<String> purchasedBorderIds;
  final void Function(TileBorderStyle style) onStyleSelected;
  final void Function(TileBorderStyle style) onLockedTap;

  const _StyleGrid({
    required this.styles,
    required this.selectedStyleId,
    required this.tileColor,
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
          highlighted: false,
        );
        final isLocked =
            style.isPremium && !purchasedBorderIds.contains(style.id);
        final isSelected = selectedStyleId == style.id;

        return _StyleChip(
          style: style,
          decoration: decoration,
          tileColor: tileColor,
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
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyleChip({
    required this.style,
    required this.decoration,
    required this.tileColor,
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