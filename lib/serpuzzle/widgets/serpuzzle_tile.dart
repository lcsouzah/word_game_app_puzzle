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
    const borderRadius = BorderRadius.all(Radius.circular(5));
    const animationDuration = Duration(milliseconds: 180);

    final Color baseColor = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceVariant.withOpacity(isEmpty ? 0.35 : 0.65);
    final Color topEdge = Color.alphaBlend(
      Colors.white.withOpacity(highlighted ? 0.4 : 0.25),
      baseColor,
    );
    final Color bottomEdge = Color.alphaBlend(
      Colors.black.withOpacity(highlighted ? 0.45 : 0.35),
      baseColor,
    );
    final Color outline = Color.alphaBlend(
      theme.colorScheme.outlineVariant.withOpacity(0.6),
      baseColor.withOpacity(0.7),
    );

    final textStyle = (theme.textTheme.titleMedium ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ))
        .copyWith(
      height: 1,
      letterSpacing: 1.4,
      color: highlighted
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface,
    );

    return AnimatedScale(
      scale: highlighted ? 1.02 : 1.0,
      duration: animationDuration,
      curve: Curves.easeOutQuad,
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius,
          border: Border.all(color: outline, width: 1.4),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border(
            top: BorderSide(color: topEdge, width: 3),
            left: BorderSide(color: topEdge, width: 3),
            right: BorderSide(color: bottomEdge, width: 3),
            bottom: BorderSide(color: bottomEdge, width: 3),
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: animationDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isEmpty
              ? const SizedBox.shrink()
              : Text(
            letter,
            key: ValueKey(letter),
            style: textStyle,
          ),
        ),
      ),
    );
  }
}