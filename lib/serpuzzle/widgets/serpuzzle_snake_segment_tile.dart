import 'package:flutter/material.dart';

/// Visual representation of a Serpuzzle snake body segment.
///
/// Unlike [SerpuzzleTile], this widget renders letters using the
/// snake-specific palette so that the body can be styled independently from
/// the board grid tiles.
class SerpuzzleSnakeSegmentTile extends StatelessWidget {
  /// Letter displayed in this segment. Empty letters render as a blank tile.
  final String letter;

  /// Whether the segment is highlighted, typically when the snake has formed
  /// a valid word.
  final bool highlighted;

  const SerpuzzleSnakeSegmentTile({
    super.key,
    this.letter = '',
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color baseColor = highlighted ? scheme.secondary : scheme.primary;
    final Color topEdge = Color.alphaBlend(
      Colors.white.withOpacity(highlighted ? 0.45 : 0.35),
      baseColor,
    );
    final Color bottomEdge = Color.alphaBlend(
      Colors.black.withOpacity(highlighted ? 0.5 : 0.4),
      baseColor,
    );
    final Color outline = Color.alphaBlend(
      scheme.outlineVariant.withOpacity(0.65),
      baseColor.withOpacity(0.75),
    );

    final trimmedLetter = letter.trim();
    final textStyle = (theme.textTheme.titleMedium ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))
        .copyWith(
      height: 1,
      letterSpacing: 1.3,
      color: highlighted ? scheme.onSecondary : scheme.onPrimary,
    );

    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: outline, width: 1.4),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border(
          top: BorderSide(color: topEdge, width: 3),
          left: BorderSide(color: topEdge, width: 3),
          right: BorderSide(color: bottomEdge, width: 3),
          bottom: BorderSide(color: bottomEdge, width: 3),
        ),
      ),
      alignment: Alignment.center,
      child: trimmedLetter.isEmpty
          ? const SizedBox.shrink()
          : Text(
        trimmedLetter,
        style: textStyle,
      ),
    );
  }
}