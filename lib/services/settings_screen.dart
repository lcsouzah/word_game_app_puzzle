import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_game_app/services/game_feedback_service.dart';
import 'package:word_game_app/services/in_app_purchase_service.dart';
import 'package:word_game_app/services/cosmetic_manager.dart';
import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/utils/text_format.dart';
import 'package:word_game_app/word_slide/ui/screens/store_screen.dart';
import 'package:word_game_app/word_slide/ui/theme/board_theme.dart';
import 'package:word_game_app/word_slide/ui/widgets/tiles.dart';


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
  Color(0xFF7E57C2),
  Color(0xFF4CAF50),
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
  Color(0xFFFFF59D),
  Color(0xFFB0BEC5),
];

const _soundPacks = <String, String>{
  'classic': 'Classic',
  'arcade': 'Arcade',
  'zen': 'Zen',
};

const _hintEffectOptions = <String, String>{
  'ring': 'Ring',
  'spotlight': 'Spotlight',
  'arrow-bounce': 'Arrow bounce',
};

/// Screen allowing the player to customise tile appearance and feedback.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final purchaseService = context.watch<InAppPurchaseService>();
    final cosmetics = context.watch<CosmeticManager>();
    final purchasedIds = purchaseService.purchasedProductIds;
    final theme = Theme.of(context);
    final devUnlockActive = kDebugMode && settings.devUnlockPremiumCosmetics;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () {
              cosmetics.restoreClassic();
              unawaited(cosmetics.persistTo(settings));
              // ADD these lines to push Classic values into SettingsService, too:
              unawaited(settings.updateTileColor(const Color(0xFF6B4AE2)));
              unawaited(settings.updateBorderColor(Colors.white));
              unawaited(settings.updateBorderStyle(TileBorderStyles.classicOutline, allowPremium: true));
              unawaited(settings.updateBoardStyle(BoardStyles.classicNeutral, allowPremium: true));
              unawaited(settings.updateTileAnimationStyle(TileAnimationStyles.slide, allowPremium: true));
              unawaited(settings.updateSoundPack('classic'));
              unawaited(settings.updateIdleShimmerEnabled(false));

              // (Optional) ensure hint effect is the classic one:
              unawaited(settings.updateHintEffect('hint.inner_pulse'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Classic preset restored.')),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Restore Classic'),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: titleCaseFirstOnly('audio'),
            children: [
              SwitchListTile(
                title: const Text('Sound enabled'),
                subtitle: const Text('Toggle all effects'),
                value: settings.soundEnabled,
                onChanged: (value) => unawaited(settings.updateSoundEnabled(value)),
              ),
              ListTile(
                title: const Text('Sound pack'),
                subtitle: const Text('Choose effect style'),
                trailing: DropdownButton<String>(
                  value: settings.soundPack,
                  onChanged: (value) {
                    if (value != null) {
                      unawaited(settings.updateSoundPack(value));
                    }
                  },
                  items: _soundPacks.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: titleCaseFirstOnly('haptics'),
            children: [
              SwitchListTile(
                title: const Text('Haptics enabled'),
                subtitle: const Text('Vibrate on moves and success'),
                value: settings.hapticsEnabled,
                onChanged: (value) => unawaited(settings.updateHapticsEnabled(value)),
              ),
              ListTile(
                title: const Text('Move intensity'),
                trailing: DropdownButton<MoveHapticIntensity>(
                  value: settings.moveHapticIntensity,
                  onChanged: (value) {
                    if (value != null) {
                      unawaited(settings.updateMoveHapticIntensity(value));
                    }
                  },
                  items: MoveHapticIntensity.values
                      .map(
                        (value) => DropdownMenuItem<MoveHapticIntensity>(
                      value: value,
                      child: Text(switch (value) {
                        MoveHapticIntensity.light => 'Light',
                        MoveHapticIntensity.medium => 'Medium',
                      }),
                    ),
                  )
                      .toList(),
                ),
              ),
              ListTile(
                title: const Text('Success intensity'),
                trailing: DropdownButton<SuccessHapticIntensity>(
                  value: settings.successHapticIntensity,
                  onChanged: (value) {
                    if (value != null) {
                      unawaited(settings.updateSuccessHapticIntensity(value));
                    }
                  },
                  items: SuccessHapticIntensity.values
                      .map(
                        (value) => DropdownMenuItem<SuccessHapticIntensity>(
                      value: value,
                      child: Text(switch (value) {
                        SuccessHapticIntensity.medium => 'Medium',
                        SuccessHapticIntensity.heavy => 'Heavy',
                      }),
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: titleCaseFirstOnly('appearance / cosmetics'),
            children: [
              _SubHeader(text: titleCaseFirstOnly('tile colour')),
              _TileColorPalette(
                colors: _availableTileColors,
                selectedColor: settings.tileColor,
                onColorSelected: settings.updateTileColor,
              ),
              const SizedBox(height: 12),
              _SubHeader(text: titleCaseFirstOnly('border colour')),
              _TileColorPalette(
                colors: _availableBorderColors,
                selectedColor: settings.borderColor,
                onColorSelected: settings.updateBorderColor,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Tile border style'),
                subtitle: Text(settings.borderStyle.displayName),
                trailing: TilePreview(
                  letter: 'A',
                  tileColor: cosmetics.tileColor,
                  borderColor: cosmetics.borderColor,
                  borderStyle: cosmetics.tileBorderStyle,
                  animationStyle: cosmetics.tileAnimationStyle,
                  idleShimmerEnabled: cosmetics.idleShimmerEnabled,
                  hintEffect: cosmetics.hintEffectId,
                ),
                onTap: () => _showBorderStyleSheet(
                  context,
                  settings,
                  purchasedIds,
                  devUnlockActive,
                ),
              ),
              ListTile(
                title: const Text('Tile animation style'),
                subtitle: Text(settings.tileAnimationStyle.displayName),
                trailing: TilePreview(
                  letter: 'A',
                  tileColor: cosmetics.tileColor,
                  borderColor: cosmetics.borderColor,
                  borderStyle: cosmetics.tileBorderStyle,
                  animationStyle: cosmetics.tileAnimationStyle,
                  idleShimmerEnabled: cosmetics.idleShimmerEnabled,
                  hintEffect: cosmetics.hintEffectId,
                ),
                onTap: () => _showAnimationStyleSheet(
                  context,
                  settings,
                  purchasedIds,
                  devUnlockActive,
                ),
              ),
              ListTile(
                title: const Text('Board style'),
                subtitle: Text(settings.boardStyle.displayName),
                trailing: Icon(
                  Icons.grid_on,
                  color: theme.colorScheme.primary,
                ),
                onTap: () => _showBoardStyleSheet(
                  context,
                  settings,
                  purchasedIds,
                  devUnlockActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: titleCaseFirstOnly('hints'),
            children: [
              ListTile(
                title: const Text('Hint effect'),
                subtitle: Text(_hintEffectOptions[settings.hintEffect] ?? 'Ring'),
                trailing: TilePreview(
                  letter: 'A',
                  tileColor: cosmetics.tileColor,
                  borderColor: cosmetics.borderColor,
                  borderStyle: cosmetics.tileBorderStyle,
                  animationStyle: cosmetics.tileAnimationStyle,
                  hintEffect: cosmetics.hintEffectId,
                  showHintEffect: true,
                  idleShimmerEnabled: cosmetics.idleShimmerEnabled,
                ),
                onTap: () => _showHintEffectSheet(context, settings),
              ),
              SwitchListTile(
                title: const Text('Show hint trail'),
                subtitle: const Text('Display breadcrumb path'),
                value: settings.showHintTrail,
                onChanged: (value) => unawaited(settings.updateShowHintTrail(value)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: titleCaseFirstOnly('performance'),
            children: [
              SwitchListTile(
                title: const Text('Animated background'),
                subtitle: const Text('Enable start screen motion'),
                value: settings.animatedBackgroundEnabled,
                onChanged: (value) =>
                    unawaited(settings.updateAnimatedBackgroundEnabled(value)),
              ),
              SwitchListTile(
                title: const Text('Idle shimmer'),
                subtitle: const Text('Enable subtle tile glow'),
                value: settings.idleShimmerEnabled,
                onChanged: (value) =>
                    unawaited(settings.updateIdleShimmerEnabled(value)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: titleCaseFirstOnly('monetization / store'),
            children: [
              ListTile(
                leading: const Icon(Icons.storefront),
                title: const Text('Open store'),
                subtitle: const Text('Browse premium cosmetics'),
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
              if (kDebugMode)
                SwitchListTile(
                  title: const Text('Dev unlock premium cosmetics'),
                  subtitle: const Text('Bypass purchase checks (debug only)'),
                  value: settings.devUnlockPremiumCosmetics,
                  onChanged: (value) =>
                      unawaited(settings.updateDevUnlockPremiumCosmetics(value)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBorderStyleSheet(
      BuildContext context,
      SettingsService settings,
      Set<String> purchasedIds,
      bool devUnlockActive,
      ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _StyleGrid(
            styles: TileBorderStyles.all.toList(),
            selectedStyleId: settings.borderStyle.id,
            tileColor: settings.tileColor,
            borderColor: settings.borderColor,
            purchasedBorderIds: purchasedIds,
            onStyleSelected: (style) {
              Navigator.pop(context);
              unawaited(
                settings.updateBorderStyle(
                  style,
                  allowPremium: !style.isPremium ||
                      purchasedIds.contains(style.id) ||
                      devUnlockActive,
                ),
              );
            },
            onLockedTap: (style) => _handleLockedStyleTap(context, style),
            allowDevUnlock: devUnlockActive,
          ),
        );
      },
    );
  }

  void _showAnimationStyleSheet(
      BuildContext context,
      SettingsService settings,
      Set<String> purchasedIds,
      bool devUnlockActive,
      ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _TileAnimationGrid(
            styles: TileAnimationStyles.all.toList(),
            selectedStyleId: settings.tileAnimationStyle.id,
            purchasedProductIds: purchasedIds,
            onStyleSelected: (style) {
              Navigator.pop(context);
              unawaited(
                settings.updateTileAnimationStyle(
                  style,
                  allowPremium: !style.isPremium ||
                      purchasedIds.contains(style.id) ||
                      devUnlockActive,
                ),
              );
            },
            onLockedTap: (style) =>
                _handleLockedAnimationStyleTap(context, style),
            allowDevUnlock: devUnlockActive,
          ),
        );
      },
    );
  }

  void _showBoardStyleSheet(
      BuildContext context,
      SettingsService settings,
      Set<String> purchasedIds,
      bool devUnlockActive,
      ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _BoardStyleGrid(
            styles: BoardStyles.all.toList(),
            selectedStyleId: settings.boardStyle.id,
            purchasedProductIds: purchasedIds,
            onStyleSelected: (style) {
              Navigator.pop(context);
              unawaited(
                settings.updateBoardStyle(
                  style,
                  allowPremium: !style.isPremium ||
                      purchasedIds.contains(style.id) ||
                      devUnlockActive,
                ),
              );
            },
            onLockedTap: (style) => _handleLockedBoardStyleTap(context, style),
            allowDevUnlock: devUnlockActive,
          ),
        );
      },
    );
  }

  void _showHintEffectSheet(BuildContext context, SettingsService settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final cosmetics = context.read<CosmeticManager>();
        return ListView(
          shrinkWrap: true,
          children: _hintEffectOptions.entries.map((entry) {
            final selected = entry.key == settings.hintEffect;
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: settings.hintEffect,
              onChanged: (value) {
                if (value != null) {
                  unawaited(settings.updateHintEffect(value));
                  Navigator.pop(context);
                }
              },
              secondary: TilePreview(
                letter: 'A',
                tileColor: cosmetics.tileColor,
                borderColor: cosmetics.borderColor,
                borderStyle: cosmetics.tileBorderStyle,
                animationStyle: cosmetics.tileAnimationStyle,
                hintEffect: entry.key,
                showHintEffect: true,
                idleShimmerEnabled: cosmetics.idleShimmerEnabled,
              ),
              selected: selected,
            );
          }).toList(),
        );
      },
    );
  }

  void _handleLockedStyleTap(BuildContext context, TileBorderStyle style) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${style.displayName} is a premium border. Visit the store to unlock it.',
        ),
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
        content: Text(
          '${style.displayName} is a premium board. Visit the store to unlock it.',
        ),
        action: SnackBarAction(
          label: 'Store',
          onPressed: () => _openStore(context),
        ),
      ),
    );
  }

  void _handleLockedAnimationStyleTap(
      BuildContext context,
      TileAnimationStyle style,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${style.displayName} is a premium animation. Visit the store to unlock it.',
        ),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _TileColorPalette extends StatelessWidget {
  const _TileColorPalette({
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final List<Color> colors;
  final Color selectedColor;
  final Future<void> Function(Color color) onColorSelected;

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
            onTap: () => unawaited(onColorSelected(color)),
          ),
      ],
    );
  }
}

class _TileColorSwatch extends StatelessWidget {
  const _TileColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

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

class _BoardStyleGrid extends StatelessWidget {
  const _BoardStyleGrid({
    required this.styles,
    required this.selectedStyleId,
    required this.purchasedProductIds,
    required this.onStyleSelected,
    required this.onLockedTap,
    this.allowDevUnlock = false,
  });

  final List<BoardStyle> styles;
  final String selectedStyleId;
  final Set<String> purchasedProductIds;
  final void Function(BoardStyle style) onStyleSelected;
  final void Function(BoardStyle style) onLockedTap;
  final bool allowDevUnlock;

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
        final isLocked = style.isPremium &&
            !purchasedProductIds.contains(style.id) &&
            !allowDevUnlock;
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
  const _BoardStyleChip({
    required this.style,
    required this.decoration,
    required this.isLocked,
    required this.isSelected,
    required this.onTap,
  });

  final BoardStyle style;
  final BoardStyleDecoration decoration;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

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

class _BoardStylePreview extends StatelessWidget {
  const _BoardStylePreview({required this.decoration});

  final BoardStyleDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: decoration.borderRadius,
        gradient: decoration.backgroundGradient,
        color: decoration.backgroundGradient == null
            ? decoration.backgroundColor
            : null,
        border: decoration.border,
        boxShadow: decoration.boxShadows,
        image: decoration.backgroundImage,
      ),
    );
  }
}

class _StyleGrid extends StatelessWidget {
  const _StyleGrid({
    required this.styles,
    required this.selectedStyleId,
    required this.tileColor,
    required this.borderColor,
    required this.purchasedBorderIds,
    required this.onStyleSelected,
    required this.onLockedTap,
    this.allowDevUnlock = false,
  });

  final List<TileBorderStyle> styles;
  final String selectedStyleId;
  final Color tileColor;
  final Color borderColor;
  final Set<String> purchasedBorderIds;
  final void Function(TileBorderStyle style) onStyleSelected;
  final void Function(TileBorderStyle style) onLockedTap;
  final bool allowDevUnlock;

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
        final decoration = style.buildDecoration(
          tileColor: tileColor,
          borderColor: borderColor,
          highlighted: false,
        );
        final isLocked = style.isPremium &&
            !purchasedBorderIds.contains(style.id) &&
            !allowDevUnlock;
        final isSelected = selectedStyleId == style.id;

        return _StyleChip(
          style: style,
          decoration: decoration,
          tileColor: tileColor,
          borderColor: borderColor,
          isLocked: isLocked,
          isSelected: isSelected,
          onTap: isLocked ? () => onLockedTap(style) : () => onStyleSelected(style),
        );
      },
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.style,
    required this.decoration,
    required this.tileColor,
    required this.borderColor,
    required this.isLocked,
    required this.isSelected,
    required this.onTap,
  });

  final TileBorderStyle style;
  final TileBorderDecoration decoration;
  final Color tileColor;
  final Color borderColor;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

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
                  child: TilePreview(
                    letter: 'A',
                    tileColor: tileColor,
                    borderColor: borderColor,
                    borderStyle: style,
                    animationStyle: TileAnimationStyles.defaultStyle,
                    idleShimmerEnabled: false,
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
  const _TileAnimationGrid({
    required this.styles,
    required this.selectedStyleId,
    required this.purchasedProductIds,
    required this.onStyleSelected,
    required this.onLockedTap,
    this.allowDevUnlock = false,
  });

  final List<TileAnimationStyle> styles;
  final String selectedStyleId;
  final Set<String> purchasedProductIds;
  final void Function(TileAnimationStyle style) onStyleSelected;
  final void Function(TileAnimationStyle style) onLockedTap;
  final bool allowDevUnlock;

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
        final isLocked = style.isPremium &&
            !purchasedProductIds.contains(style.id) &&
            !allowDevUnlock;
        final isSelected = selectedStyleId == style.id;

        return _TileAnimationChip(
          style: style,
          isLocked: isLocked,
          isSelected: isSelected,
          onTap: isLocked ? () => onLockedTap(style) : () => onStyleSelected(style),
        );
      },
    );
  }
}

class _TileAnimationChip extends StatelessWidget {
  const _TileAnimationChip({
    required this.style,
    required this.isLocked,
    required this.isSelected,
    required this.onTap,
  });

  final TileAnimationStyle style;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlightColor = Theme.of(context).colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? highlightColor : Colors.transparent,
                      width: 3,
                    ),
                    color: Colors.grey.shade900.withOpacity(0.12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(style.icon, size: 28, color: highlightColor),
                      const SizedBox(height: 8),
                      Text(
                        style.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        style.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black45,
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
      ],
    );
  }
}