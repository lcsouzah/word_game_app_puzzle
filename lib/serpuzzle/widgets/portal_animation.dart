import 'package:flutter/material.dart';

/// A simple overlay animation shown when advancing to a new level.
class PortalAnimation extends StatefulWidget {
  final int level;

  const PortalAnimation({super.key, required this.level});

  @override
  State<PortalAnimation> createState() => _PortalAnimationState();
}

class _PortalAnimationState extends State<PortalAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: ScaleTransition(
          scale: _controller,
          child: Text(
            'Level ${widget.level}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}