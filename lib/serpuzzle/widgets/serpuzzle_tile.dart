import 'package:flutter/material.dart';

/// A single grid tile used in the Serpuzzle game board.
///
/// Displays the [letter] in the centre of the tile. When [highlighted]
/// the tile is emphasised with a brighter colour. When the [letter] is an
/// empty string the tile renders as transparent and shows no text.
class SerpuzzleTile extends StatelessWidget {
  /// Letter displayed in this tile. If empty, the tile is considered blank.
  final String letter;

  /// Whether the tile should be highlighted.
  final bool highlighted;

  const SerpuzzleTile({
    super.key,
    this.letter = '',
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = letter.trim().isEmpty;
    const borderRadius = BorderRadius.all(Radius.circular(8));
    const animationDuration = Duration(milliseconds: 200);

    final gradient = isEmpty
        ? LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.deepOrange.withValues(alpha: 0.08),
        Colors.greenAccent.withValues(alpha: 0.1),
      ],
    )
        : highlighted
        ? LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.greenAccent.withValues(alpha: 0.95),
        Colors.tealAccent.withValues(alpha: 0.85),
      ],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2F3F58),
        Color(0xFF3D546B),
      ],
    );

    final textColor = highlighted ? Colors.black87 : Colors.white;
    final shadow = highlighted
        ? [
      BoxShadow(
        color: Colors.greenAccent.withValues(alpha: 0.45),
        blurRadius: 20,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
    ]
        : [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 10,
        spreadRadius: 1,
        offset: const Offset(2, 4),
      ),
    ];

    return AnimatedScale(
      scale: highlighted ? 1.05 : 1.0,
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: borderRadius,
          boxShadow: shadow,
          border: isEmpty
              ? Border.all(
            color: Colors.deepOrangeAccent.withValues(alpha: 0.25),
            width: 1,
          )
              : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              if (isEmpty)
                const Positioned.fill(
                  child: _TilePatternOverlay(),
                ),
              if (!isEmpty)
                Text(
                  letter,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TilePatternOverlay extends StatelessWidget {
  const _TilePatternOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TilePatternPainter(
        baseColor: Colors.deepOrangeAccent,
        highlightColor: Colors.greenAccent,
      ),
    );
  }
}

class _TilePatternPainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;

  const _TilePatternPainter({
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final diagonalPaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..color = baseColor.withValues(alpha: 0.14);

    final offset = size.shortestSide * 0.18;
    canvas
      ..drawLine(
        Offset(-offset, offset),
        Offset(size.width + offset, size.height - offset),
        diagonalPaint,
      )
      ..drawLine(
        Offset(-offset, size.height - offset),
        Offset(size.width + offset, offset),
        diagonalPaint..color = highlightColor.withValues(alpha: 0.12),
      );

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = highlightColor.withValues(alpha: 0.15);
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * 0.32,
      circlePaint,
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = baseColor.withValues(alpha: 0.05);
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * 0.22,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TilePatternPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.highlightColor != highlightColor;
  }
}