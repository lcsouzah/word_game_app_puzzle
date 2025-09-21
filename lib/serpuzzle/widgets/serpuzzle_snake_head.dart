import 'package:flutter/material.dart';

enum SnakeDirection { up, down, left, right }

class SerpuzzleSnakeHead extends StatelessWidget {
  final SnakeDirection direction;
  final bool highlighted;
  final double tileSize;

  const SerpuzzleSnakeHead({
    super.key,
    required this.direction,
    required this.highlighted,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    final margin = tileSize * 0.075;
    final borderRadius = tileSize * 0.2;
    final baseColor = highlighted
        ? Colors.greenAccent.withValues(alpha: 0.8)
        : Colors.deepOrange;
    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: CustomPaint(
        painter: _SnakeHeadPainter(
          direction: direction,
          arrowColor: highlighted ? Colors.black87 : Colors.white,
          eyeColor: highlighted ? Colors.white : Colors.black87,
          tongueColor: highlighted ? Colors.red.shade200 : Colors.redAccent,
        ),
      ),
    );
  }
}

class _SnakeHeadPainter extends CustomPainter {
  final SnakeDirection direction;
  final Color arrowColor;
  final Color eyeColor;
  final Color tongueColor;

  const _SnakeHeadPainter({
    required this.direction,
    required this.arrowColor,
    required this.eyeColor,
    required this.tongueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;

    final Path arrowPath = Path();
    final double inset = shortest * 0.18;
    switch (direction) {
      case SnakeDirection.up:
        arrowPath
          ..moveTo(size.width / 2, inset)
          ..lineTo(size.width - inset, size.height - inset)
          ..lineTo(inset, size.height - inset)
          ..close();
        break;
      case SnakeDirection.down:
        arrowPath
          ..moveTo(inset, inset)
          ..lineTo(size.width - inset, inset)
          ..lineTo(size.width / 2, size.height - inset)
          ..close();
        break;
      case SnakeDirection.left:
        arrowPath
          ..moveTo(inset, size.height / 2)
          ..lineTo(size.width - inset, inset)
          ..lineTo(size.width - inset, size.height - inset)
          ..close();
        break;
      case SnakeDirection.right:
        arrowPath
          ..moveTo(size.width - inset, size.height / 2)
          ..lineTo(inset, size.height - inset)
          ..lineTo(inset, inset)
          ..close();
        break;
    }

    canvas.drawPath(arrowPath, arrowPaint);

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;

    final double eyeRadius = shortest * 0.08;
    final double pupilRadius = shortest * 0.04;
    final eyeOffsets = _eyePositions(direction, size);
    for (final offset in eyeOffsets) {
      canvas
        ..drawCircle(offset, eyeRadius, eyePaint)
        ..drawCircle(offset, pupilRadius, pupilPaint);
    }

    final tonguePaint = Paint()
      ..color = tongueColor
      ..style = PaintingStyle.fill;
    final tonguePath = _tonguePath(direction, size, shortest * 0.1);
    canvas.drawPath(tonguePath, tonguePaint);
  }

  List<Offset> _eyePositions(SnakeDirection direction, Size size) {
    final width = size.width;
    final height = size.height;
    switch (direction) {
      case SnakeDirection.up:
        return [
          Offset(width * 0.35, height * 0.35),
          Offset(width * 0.65, height * 0.35),
        ];
      case SnakeDirection.down:
        return [
          Offset(width * 0.35, height * 0.65),
          Offset(width * 0.65, height * 0.65),
        ];
      case SnakeDirection.left:
        return [
          Offset(width * 0.35, height * 0.35),
          Offset(width * 0.35, height * 0.65),
        ];
      case SnakeDirection.right:
        return [
          Offset(width * 0.65, height * 0.35),
          Offset(width * 0.65, height * 0.65),
        ];
    }
  }

  Path _tonguePath(SnakeDirection direction, Size size, double length) {
    final path = Path();
    switch (direction) {
      case SnakeDirection.up:
        path
          ..moveTo(size.width / 2 - length / 3, size.height * 0.05)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width / 2 + length / 3, size.height * 0.05)
          ..close();
        break;
      case SnakeDirection.down:
        path
          ..moveTo(size.width / 2 - length / 3, size.height - size.height * 0.05)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width / 2 + length / 3, size.height - size.height * 0.05)
          ..close();
        break;
      case SnakeDirection.left:
        path
          ..moveTo(size.width * 0.05, size.height / 2 - length / 3)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width * 0.05, size.height / 2 + length / 3)
          ..close();
        break;
      case SnakeDirection.right:
        path
          ..moveTo(size.width - size.width * 0.05, size.height / 2 - length / 3)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width - size.width * 0.05, size.height / 2 + length / 3)
          ..close();
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _SnakeHeadPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.arrowColor != arrowColor ||
        oldDelegate.eyeColor != eyeColor ||
        oldDelegate.tongueColor != tongueColor;
  }
}