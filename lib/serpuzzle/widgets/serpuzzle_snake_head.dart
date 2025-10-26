import 'package:flutter/material.dart';
import 'package:word_game_app/serpuzzle/serpuzzle_tunables.dart';

enum SnakeDirection { up, down, left, right }

class SerpuzzleSnakeHead extends StatefulWidget {
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
  SerpuzzleSnakeHeadState createState() => SerpuzzleSnakeHeadState();
}

class SerpuzzleSnakeHeadState extends State<SerpuzzleSnakeHead>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: headPulseDuration,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 45,
      ),
    ]).animate(_controller);
  }

  void pulse() {
    if (!mounted) return;
    _controller
      ..stop()
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color baseColor = widget.highlighted ? scheme.secondary : scheme.primary;
    final Color topEdge = Color.alphaBlend(
      Colors.white.withOpacity(widget.highlighted ? 0.45 : 0.35),
      baseColor,
    );
    final Color bottomEdge = Color.alphaBlend(
      Colors.black.withOpacity(widget.highlighted ? 0.5 : 0.4),
      baseColor,
    );
    final shadows = <BoxShadow>[
      BoxShadow(
        color: bottomEdge.withOpacity(widget.highlighted ? 0.48 : 0.35),
        offset: const Offset(0, 2.6),
        blurRadius: widget.highlighted ? 10 : 6,
        spreadRadius: widget.highlighted ? 1.4 : 0.6,
      ),
      BoxShadow(
        color: baseColor.withOpacity(widget.highlighted ? 0.4 : 0.28),
        blurRadius: widget.highlighted ? 26 : 18,
        spreadRadius: widget.highlighted ? 3.2 : 2,
      ),
    ];

    final head = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            topEdge,
            baseColor,
            bottomEdge,
          ],
          stops: const [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: shadows,
      ),
      child: CustomPaint(
        painter: _SnakeHeadPainter(
          direction: widget.direction,
          arrowColor:
          widget.highlighted ? scheme.onSecondary : scheme.onPrimary,
          eyeColor: widget.highlighted ? scheme.onSecondary : scheme.onPrimary,
          tongueColor: widget.highlighted
              ? scheme.onSecondary.withOpacity(0.9)
              : Colors.lightGreen,
        ),
      ),
    );

    return ScaleTransition(
      scale: _scale,
      child: head,
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