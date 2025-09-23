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
    final isDark = theme.brightness == Brightness.dark;

    final Color baseColor = highlighted
        ? scheme.tertiaryContainer
        : scheme.primaryContainer;
    final Color accentColor = highlighted ? scheme.tertiary : scheme.primary;
    final Color outlineColor = Color.alphaBlend(
      accentColor.withOpacity(isDark ? 0.55 : 0.35),
      scheme.outlineVariant.withOpacity(0.6),
    );

    final gradient = LinearGradient(
      colors: [
        Color.alphaBlend(
          accentColor.withOpacity(isDark ? 0.28 : 0.18),
          baseColor,
        ),
        baseColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final textStyle = (theme.textTheme.titleMedium ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))
        .copyWith(
      fontWeight: FontWeight.w700,
      color:
      highlighted ? scheme.onTertiaryContainer : scheme.onPrimaryContainer,
      letterSpacing: 0.4,
    );

    final shadowColor = highlighted
        ? accentColor.withOpacity(isDark ? 0.55 : 0.45)
        : Colors.black.withOpacity(isDark ? 0.4 : 0.2);

    final trimmedLetter = letter.trim();

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: outlineColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 3),
            blurRadius: highlighted ? 10 : 6,
            spreadRadius: highlighted ? 1.5 : 0.5,
          ),
        ],
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