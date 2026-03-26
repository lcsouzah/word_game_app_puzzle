import 'package:flutter/material.dart';
import 'package:word_game_app/serpuzzle/serpuzzle_tunables.dart';

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
class SerpuzzleSnakeBody extends StatefulWidget {
  const SerpuzzleSnakeBody({
    super.key,
    required this.segments,
    required this.tileSize,
    required this.headKey,
    required this.headCurrentPixel,
    required this.headNextPixel,
    required this.headProgress,
  });

  final List<SnakeSegment> segments;
  final double tileSize;
  final GlobalKey<SerpuzzleSnakeHeadState> headKey;
  final Offset headCurrentPixel;
  final Offset headNextPixel;
  final double headProgress;

  @override
  State<SerpuzzleSnakeBody> createState() => _SerpuzzleSnakeBodyState();
}

class _SerpuzzleSnakeBodyState extends State<SerpuzzleSnakeBody> {
  final List<Offset> _trail = <Offset>[];

  @override
  void initState() {
    super.initState();
    _resetTrail();
  }

  @override
  void didUpdateWidget(covariant SerpuzzleSnakeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tileSize != oldWidget.tileSize ||
        widget.segments.length != oldWidget.segments.length) {
      _resetTrail();
    } else if (widget.segments.isNotEmpty) {
      final headCenter = _lerpedHeadPosition();
      if (_trail.isEmpty ||
          (_trail.first - headCenter).distance > widget.tileSize * 1.5) {
        _resetTrail();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.segments.isEmpty) {
      return const SizedBox.shrink();
    }

    _updateTrail();
    final centers = _computeSegmentCenters();
    final segmentSize = widget.tileSize;
    final headDirection = _resolveHeadDirection(centers);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < widget.segments.length; i++)
          Positioned(
            left: centers[i].dx - segmentSize / 2,
            top: centers[i].dy - segmentSize / 2,
            child: AnimatedOpacity(
              duration: kPerTileAnim,
              opacity: widget.segments[i].fading ? 0 : 1,
              child: SizedBox(
                width: segmentSize,
                height: segmentSize,
                child: _buildSegment(
                  index: i,
                  size: segmentSize,
                  direction: headDirection,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSegment({
    required int index,
    required double size,
    required SnakeDirection direction,
  }) {
    final segment = widget.segments[index];
    final isHead = index == widget.segments.length - 1;
    if (!isHead) {
      return SerpuzzleSnakeSegmentTile(
        letter: segment.letter,
        highlighted: segment.highlighted,
      );
    }

    return SerpuzzleSnakeHead(
      key: widget.headKey,
      direction: direction,
      highlighted: segment.highlighted,
      tileSize: size,
    );
  }

  void _resetTrail() {
    _trail.clear();
    if (widget.segments.isEmpty) {
      return;
    }
    for (var i = widget.segments.length - 1; i >= 0; i--) {
      final segment = widget.segments[i];
      _trail.add(_segmentCenter(segment));
    }
  }

  void _updateTrail() {
    final headPosition = _lerpedHeadPosition();
    if (_trail.isEmpty) {
      _trail.add(headPosition);
    } else {
      final delta = (_trail.first - headPosition).distance;
      if (delta > 0.5) {
        _trail.insert(0, headPosition);
      } else {
        _trail[0] = headPosition;
      }
    }

    final maxDistance = widget.tileSize * segmentOverlapFactor *
        (widget.segments.length + 2);
    _trimTrail(maxDistance);
  }

  void _trimTrail(double maxDistance) {
    if (_trail.length < 2) return;
    double distance = 0;
    for (var i = 0; i < _trail.length - 1; i++) {
      distance += (_trail[i] - _trail[i + 1]).distance;
      if (distance > maxDistance) {
        final removalStart = (i + 2).clamp(0, _trail.length);
        if (removalStart < _trail.length) {
          _trail.removeRange(removalStart, _trail.length);
        }
        break;
      }
    }
  }

  List<Offset> _computeSegmentCenters() {
    final count = widget.segments.length;
    final centers = List<Offset>.filled(count, Offset.zero);
    final spacing = widget.tileSize * segmentOverlapFactor;
    for (var i = count - 1; i >= 0; i--) {
      final distance = (count - 1 - i) * spacing;
      centers[i] = _sampleTrail(distance);
    }
    return centers;
  }

  Offset _sampleTrail(double targetDistance) {
    if (_trail.isEmpty) {
      return _lerpedHeadPosition();
    }
    double traversed = 0;
    for (var i = 0; i < _trail.length - 1; i++) {
      final start = _trail[i];
      final end = _trail[i + 1];
      final segmentLength = (start - end).distance;
      if (segmentLength == 0) {
        continue;
      }
      if (traversed + segmentLength >= targetDistance) {
        final remaining = targetDistance - traversed;
        final t = (remaining / segmentLength).clamp(0.0, 1.0);
        return Offset.lerp(start, end, t) ?? end;
      }
      traversed += segmentLength;
    }
    return _trail.last;
  }

  SnakeDirection _resolveHeadDirection(List<Offset> centers) {
    if (centers.length < 2) {
      return SnakeDirection.right;
    }
    final delta = centers.last - centers[centers.length - 2];
    if (delta.dx.abs() >= delta.dy.abs()) {
      return delta.dx >= 0 ? SnakeDirection.right : SnakeDirection.left;
    }
    return delta.dy >= 0 ? SnakeDirection.down : SnakeDirection.up;
  }

  Offset _lerpedHeadPosition() {
    return Offset.lerp(
      widget.headCurrentPixel,
      widget.headNextPixel,
      widget.headProgress.clamp(0.0, 1.0),
    ) ??
        widget.headCurrentPixel;
  }

  Offset _segmentCenter(SnakeSegment segment) {
    return Offset(
      (segment.col + 0.5) * widget.tileSize,
      (segment.row + 0.5) * widget.tileSize,
    );
  }
}
