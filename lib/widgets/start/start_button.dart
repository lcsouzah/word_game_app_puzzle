import 'package:flutter/material.dart';

class StartButton extends StatelessWidget {
  final VoidCallback onTap;

  const StartButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        splashColor: Colors.orangeAccent.withValues(alpha: 0.5),
        highlightColor: Colors.orangeAccent.withValues(alpha: 0.2),
        onTap: onTap,
        child: const SizedBox.expand(),
      ),
    );
  }
}