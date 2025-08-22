



import 'package:flutter/material.dart';

class TouchFeedbackOverlay extends StatefulWidget {
  final Widget child;

  const TouchFeedbackOverlay({super.key, required this.child});

  @override
  State<TouchFeedbackOverlay> createState() => _TouchFeedbackOverlayState();
}

class _TouchFeedbackOverlayState extends State<TouchFeedbackOverlay> {
  final List<Offset> _tapPositions = [];

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _tapPositions.add(details.globalPosition);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _tapPositions.isNotEmpty) {
        setState(() {
          _tapPositions.removeAt(0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _handleTapDown,
      child: Stack(
        children: [
          widget.child,
          ..._tapPositions.map((pos) => Positioned(
            left: pos.dx - 15,
            top: pos.dy - 15,
            child: IgnorePointer(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
