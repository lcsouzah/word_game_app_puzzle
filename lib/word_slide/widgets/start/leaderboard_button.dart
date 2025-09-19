import 'package:flutter/material.dart';

class LeaderboardButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const LeaderboardButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        splashColor: Colors.purpleAccent.withValues(alpha: 0.5),
        highlightColor: Colors.purpleAccent.withValues(alpha: 0.2),
        onTap: () {
          onTap();
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}