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
        Color.alphaBlend(Colors.white.withOpacity(0.16), baseColor),
        baseColor.withOpacity(0.82),
      ],
    );

    final glowColor = highlighted ? scheme.secondary : scheme.primary;
    final List<BoxShadow> glow = [
      BoxShadow(
        color: glowColor.withOpacity(highlighted ? 0.45 : 0.32),
        blurRadius: highlighted ? 22 : 16,
        spreadRadius: highlighted ? 2.6 : 1.4,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.25),
        offset: const Offset(0, 3),
        blurRadius: 10,
      ),
    ];

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
        boxShadow: glow,
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