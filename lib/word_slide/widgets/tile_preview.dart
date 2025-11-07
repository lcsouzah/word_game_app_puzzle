import 'package:flutter/material.dart';
import 'package:word_game_app/word_slide/models/tile_animation_style.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';
import 'package:word_game_app/word_slide/models/tile_highlight_kind.dart';
import 'package:word_game_app/word_slide/widgets/tile.dart';

/// Lightweight preview widget that renders a single tile using the current
/// cosmetic selections. This mirrors the runtime [TileWidget] behaviour to
/// ensure settings previews match gameplay visuals.
class TilePreview extends StatelessWidget {
  const TilePreview({
    super.key,
    required this.letter,
    required this.tileColor,
    required this.borderColor,
    required this.borderStyle,
    required this.animationStyle,
    this.hintEffect = 'ring',
    this.showHintEffect = false,
    this.idleShimmerEnabled = false,
  });

  final String letter;
  final Color tileColor;
  final Color borderColor;
  final TileBorderStyle borderStyle;
  final TileAnimationStyle animationStyle;
  final String hintEffect;
  final bool showHintEffect;
  final bool idleShimmerEnabled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 64,
        height: 64,
        child: TileWidget(
          letter: letter,
          onTap: () {},
          tileColor: tileColor,
          borderColor: borderColor,
          borderStyle: borderStyle,
          animationStyle: animationStyle,
          highlighted: showHintEffect,
          highlightKind:
          showHintEffect ? TileHighlightKind.hint : TileHighlightKind.none,
          hintEffect: hintEffect,
          idleShimmerEnabled: idleShimmerEnabled,
          letterColor: Colors.white,
          borderWidth: 2.0,
        ),
      ),
    );
  }
}

/// Test helper
/// ```dart
/// final manager = CosmeticManager()..restoreClassic();
/// manager.beginHint({const TileCoord(0, 0)});
/// manager.endHint();
/// ```