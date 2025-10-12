import 'dart:ui';

import 'package:flutter/material.dart';
/// A single grid tile used in the Serpuzzle game board.
///
/// Displays the [letter] in the centre of the tile. When [highlighted]
/// the tile is emphasised with a brighter colour. When the [letter] is an
/// empty string the tile renders as transparent and shows no text.
class SerpuzzleTile extends StatefulWidget {
  /// Letter displayed in this tile. If empty, the tile is considered blank.
  final String letter;

  /// Whether the tile should be highlighted.
  final bool highlighted;

  /// Indicates that this tile's letter was just eaten by the snake.
  final bool justEaten;

  const SerpuzzleTile({
    super.key,
    this.letter = '',
    this.highlighted = false,
    this.justEaten = false,
  });

  @override
  State<SerpuzzleTile> createState() => _SerpuzzleTileState();
}

class _SerpuzzleTileState extends State<SerpuzzleTile> {
  String? _eatenLetter;
  int _eatenAnimationId = 0;

  @override
  void didUpdateWidget(covariant SerpuzzleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLetter = widget.letter.trim();
    if (newLetter.isNotEmpty && _eatenLetter != null) {
      setState(() {
        _eatenLetter = null;
      });
      return;
    }

    final becameJustEaten = widget.justEaten && !oldWidget.justEaten;
    if (becameJustEaten) {
      final previousLetter = oldWidget.letter.trim().isNotEmpty
          ? oldWidget.letter
          : widget.letter;
      if (previousLetter.trim().isNotEmpty) {
        setState(() {
          _eatenLetter = previousLetter;
          _eatenAnimationId++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = widget.letter.trim().isEmpty;
    const animationDuration = Duration(milliseconds: 160);

    final textStyle = (theme.textTheme.titleMedium ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))
        .copyWith(
      height: 1,
      letterSpacing: 1.3,
      color: widget.highlighted
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface.withOpacity(0.85),
      shadows: const [Shadow(blurRadius: 6, offset: Offset(0, 2))],
    );

    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: animationDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isEmpty
                ? const SizedBox.shrink()
                : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.letter,
                key: ValueKey(widget.letter),
                style: textStyle,
              ),
            ),
          ),
          if (_eatenLetter != null)
            TweenAnimationBuilder<double>(
              key: ValueKey<int>(_eatenAnimationId),
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              onEnd: () {
                if (!mounted) return;
                setState(() {
                  _eatenLetter = null;
                });
              },
              builder: (context, progress, child) {
                final eased = Curves.easeOut.transform(progress);
                final scale = lerpDouble(1.0, 1.35, eased) ?? 1.0;
                final fade = 1 - Curves.easeIn.transform(progress.clamp(0.0, 1.0));
                return Opacity(
                  opacity: fade.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _eatenLetter!,
                  key: ValueKey<String>('eaten-$_eatenAnimationId-$_eatenLetter'),
                  style: textStyle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}