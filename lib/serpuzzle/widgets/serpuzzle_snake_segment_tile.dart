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
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.92),
        baseColor.withOpacity(0.78),
      ],
    );

    final trimmedLetter = letter.trim();
    final textStyle = (theme.textTheme.titleMedium ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))
        .copyWith(
      height: 1,
      letterSpacing: 1.3,
      color: highlighted ? scheme.onSecondary : scheme.onPrimary,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: highlighted
              ? scheme.secondaryContainer.withOpacity(0.9)
              : scheme.outlineVariant.withOpacity(0.35),
          width: highlighted ? 1.2 : 0.9,
        ),
        boxShadow: highlighted
            ? [
          BoxShadow(
            color: scheme.secondary.withOpacity(0.45),
            blurRadius: 10,
            spreadRadius: 0.4,
          ),
        ]
            : const [],
      ),
      alignment: Alignment.center,
      child: trimmedLetter.isEmpty
          ? const SizedBox.shrink()
          : FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          trimmedLetter,
          style: textStyle,
        ),
      ),
    );
  }
}