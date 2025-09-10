import 'package:flutter/material.dart';

import 'serpuzzle_tile.dart';

/// Data describing a single segment of the snake.
class SnakeSegment {
  final int row;
  final int col;
  final String letter;
  final bool highlighted;
  final bool fading;

  const SnakeSegment({
    required this.row,
    required this.col,
    this.letter = '',
    this.highlighted = false,
    this.fading = false,
  });
}

/// Widget responsible for painting the snake body on the game board.
///
/// Each segment is positioned on the grid based on its [row] and [col]
/// coordinates. When [SnakeSegment.fading] is true the segment will fade out,
/// allowing cleared letters to disappear smoothly.
class SerpuzzleSnakeBody extends StatelessWidget {
  final List<SnakeSegment> segments;
  final double tileSize;

  const SerpuzzleSnakeBody({
    super.key,
    required this.segments,
    this.tileSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < segments.length; i++)
          AnimatedPositioned(
            // Use the segment's coordinates as the key so that each segment
            // remains uniquely identifiable even as segments are added or
            // removed from the list.
            key: ValueKey('${segments[i].row}-${segments[i].col}'),
            duration: const Duration(milliseconds: 150),
            left: segments[i].col * tileSize,
            top: segments[i].row * tileSize,
            child: AnimatedOpacity(
              opacity: segments[i].fading ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                width: tileSize,
                height: tileSize,
                child: SerpuzzleTile(
                  letter: segments[i].letter,
                  highlighted: segments[i].highlighted,
                  isHead: i == segments.length - 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}