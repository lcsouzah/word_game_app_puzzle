import 'package:flutter/material.dart';

import 'serpuzzle_snake_head.dart';
import 'serpuzzle_snake_segment_tile.dart';

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
  final double segmentScale;

  const SerpuzzleSnakeBody({
    super.key,
    required this.segments,
    this.tileSize = 40,
    this.segmentScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveScale = segmentScale <= 0 ? 1.0 : segmentScale;
    final scaledTileSize = tileSize * effectiveScale;
    final offset = (tileSize - scaledTileSize) / 2;
    return Stack(
      children: [
        for (var i = 0; i < segments.length; i++)
          AnimatedPositioned(
            // Use the segment's coordinates as the key so that each segment
            // remains uniquely identifiable even as segments are added or
            // removed from the list.
            key: ValueKey('${segments[i].row}-${segments[i].col}'),
            duration: const Duration(milliseconds: 150),
            left: segments[i].col * tileSize + offset,
            top: segments[i].row * tileSize + offset,
            child: AnimatedOpacity(
              opacity: segments[i].fading ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                width: scaledTileSize,
                height: scaledTileSize,
                child: _buildSegment(i, scaledTileSize),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSegment(int index, double segmentSize) {
    final segment = segments[index];
    final isHead = index == segments.length - 1;
    if (!isHead) {
      return SerpuzzleSnakeSegmentTile(
        letter: segment.letter,
        highlighted: segment.highlighted,
      );
    }

    final direction = _resolveHeadDirection();
    return SerpuzzleSnakeHead(
      direction: direction,
      highlighted: segment.highlighted,
      tileSize: segmentSize,
    );
  }


  SnakeDirection _resolveHeadDirection() {
    if (segments.length < 2) {
      return SnakeDirection.right;
    }

    final head = segments.last;
    final previous = segments[segments.length - 2];
    final rowDelta = head.row - previous.row;
    final colDelta = head.col - previous.col;

    if (rowDelta > 0) {
      return SnakeDirection.down;
    } else if (rowDelta < 0) {
      return SnakeDirection.up;
    } else if (colDelta > 0) {
      return SnakeDirection.right;
    } else if (colDelta < 0) {
      return SnakeDirection.left;
    }

    return SnakeDirection.right;
  }
}