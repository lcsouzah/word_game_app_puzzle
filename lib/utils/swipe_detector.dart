import 'package:flutter/material.dart';

import 'direction_enum.dart';

typedef SwipeCallback = void Function(Direction direction);

class SwipeDetector extends StatefulWidget {
  final Widget child;
  final SwipeCallback onSwipe;
  const SwipeDetector({super.key, required this.child, required this.onSwipe});

  @override
  State<SwipeDetector> createState() => _SwipeDetectorState();
}

class _SwipeDetectorState extends State<SwipeDetector> {
  Offset? _startPosition;
  static const double _threshold = 20;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _startPosition = details.localPosition;
      },
      onPanEnd: (details) {
        _startPosition = null;
      },
      onPanUpdate: (details) {
        if (_startPosition == null) return;
        final offset = details.localPosition - _startPosition!;
        if (offset.distance < _threshold) return;
        final absDx = offset.dx.abs();
        final absDy = offset.dy.abs();
        Direction direction;
        if (absDx > absDy) {
          direction = offset.dx > 0 ? Direction.right : Direction.left;
        } else {
          direction = offset.dy > 0 ? Direction.down : Direction.up;
        }
        widget.onSwipe(direction);
        _startPosition = null;
      },
      child: widget.child,
    );
  }
}