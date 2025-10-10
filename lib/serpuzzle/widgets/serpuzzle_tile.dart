import 'package:flutter/material.dart';
import 'dart:ui';
/// A single grid tile used in the Serpuzzle game board.
///
/// Displays the [letter] in the centre of the tile. When [highlighted]
/// the tile is emphasised with a brighter colour. When the [letter] is an
/// empty string the tile renders as transparent and shows no text.
class SerpuzzleTile extends StatelessWidget {
  /// Letter displayed in this tile. If empty, the tile is considered blank.
  final String letter;

  /// Whether the tile should be highlighted.
  final bool highlighted;

  const SerpuzzleTile({
    super.key,
    this.letter = '',
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = letter.trim().isEmpty;
    const animationDuration = Duration(milliseconds: 160);



    final textStyle = (theme.textTheme.titleMedium ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))
        .copyWith(
      height: 1,
      letterSpacing: 1.3,
      color: highlighted
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface.withOpacity(0.85),
      shadows: const [Shadow(blurRadius: 6, offset: Offset(0, 2))],
    );


    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration: animationDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: isEmpty
            ? const SizedBox.shrink()
            : FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            letter,
            key: ValueKey(letter),
            style: textStyle,
          ),
        ),
      ),
    );
  }
}