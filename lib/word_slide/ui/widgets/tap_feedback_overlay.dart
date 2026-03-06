



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
    final ripples = _tapPositions
        .map(
          (pos) => Positioned(
        left: pos.dx - 12,
        top: pos.dy - 12,
        child: IgnorePointer(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _handleTapDown,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(children: ripples),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}