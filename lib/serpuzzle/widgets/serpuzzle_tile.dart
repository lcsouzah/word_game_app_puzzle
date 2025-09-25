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
    final rect = Offset.zero & size;
    final background = RRect.fromRectAndRadius(
      rect.deflate(size.shortestSide * 0.12),
      Radius.circular(size.shortestSide * 0.24),
    );
    final backdropPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          highlightColor.withValues(alpha: 0.18),
          baseColor.withValues(alpha: 0.1),
        ],
      ).createShader(background.outerRect);
    canvas.drawRRect(background, backdropPaint);

    final bubblePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = highlightColor.withValues(alpha: 0.22);
    final bubbleRadius = size.shortestSide * 0.1;
    canvas
      ..drawCircle(
        Offset(size.width * 0.3, size.height * 0.32),
        bubbleRadius,
        bubblePaint,
      )
      ..drawCircle(
        Offset(size.width * 0.68, size.height * 0.3),
        bubbleRadius * 0.82,
        bubblePaint..color = highlightColor.withValues(alpha: 0.16),
      )
      ..drawCircle(
        Offset(size.width * 0.48, size.height * 0.68),
        bubbleRadius * 0.75,
        bubblePaint..color = baseColor.withValues(alpha: 0.18),
      );

    final cheekPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = baseColor.withValues(alpha: 0.2);
    final cheekRadius = size.shortestSide * 0.07;
    canvas
      ..drawCircle(
        Offset(size.width * 0.36, size.height * 0.52),
        cheekRadius,
        cheekPaint,
      )
      ..drawCircle(
        Offset(size.width * 0.64, size.height * 0.52),
        cheekRadius,
        cheekPaint,
      );

    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = baseColor.withValues(alpha: 0.35);
    final eyeRadius = size.shortestSide * 0.045;
    canvas
      ..drawCircle(
        Offset(size.width * 0.38, size.height * 0.45),
        eyeRadius,
        eyePaint,
      )
      ..drawCircle(
        Offset(size.width * 0.62, size.height * 0.45),
        eyeRadius,
        eyePaint,
      );

    final smilePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.05
      ..strokeCap = StrokeCap.round
      ..color = baseColor.withValues(alpha: 0.28);
    final smilePath = Path()
      ..moveTo(size.width * 0.34, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.74,
        size.width * 0.66,
        size.height * 0.62,
      );
    canvas.drawPath(smilePath, smilePaint);

    final sparklePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.02
      ..color = highlightColor.withValues(alpha: 0.4);
    final sparkOffsets = [
      Offset(size.width * 0.18, size.height * 0.2),
      Offset(size.width * 0.82, size.height * 0.22),
    ];
    final sparkleLength = size.shortestSide * 0.07;
    for (final center in sparkOffsets) {
      canvas
        ..drawLine(
          Offset(center.dx - sparkleLength * 0.5, center.dy),
          Offset(center.dx + sparkleLength * 0.5, center.dy),
          sparklePaint,
        )
        ..drawLine(
          Offset(center.dx, center.dy - sparkleLength * 0.5),
          Offset(center.dx, center.dy + sparkleLength * 0.5),
          sparklePaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _TilePatternPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.highlightColor != highlightColor;
  }
}