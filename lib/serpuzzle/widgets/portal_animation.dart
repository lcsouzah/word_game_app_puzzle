import 'package:flutter/material.dart';

/// A simple overlay animation shown when advancing to a new level.
class PortalAnimation extends StatefulWidget {
  final int level;

  const PortalAnimation({super.key, required this.level});

  /// Convenience helper for callers that need a [GlobalKey].
  static GlobalKey<PortalAnimationState> createKey() =>
      GlobalKey<PortalAnimationState>();

  @override
  State<PortalAnimation> createState() => PortalAnimationState();
}

class PortalAnimationState extends State<PortalAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Immediately start the animation when the widget is inserted.
    play();
  }

  /// Plays the portal animation, resetting the controller each time.
  Future<void> play({bool reverse = false}) async {
    _controller.stop();
    _controller.reset();

    try {
      await _controller.forward();
      if (reverse) {
        await _controller.reverse();
      }
    } catch (_) {
      // The animation was cancelled (likely because the widget was disposed).
      return;
    }

    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: FadeTransition(
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
      ),
    );
  }
}