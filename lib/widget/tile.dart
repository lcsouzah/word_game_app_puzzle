//Y:\word_game_app_puzzle\lib\widget\tile.dart

import 'package:flutter/material.dart';

class TileWidget extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;
  final bool highlighted;

  const TileWidget({
    super.key,
    required this.letter,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            boxShadow: highlighted
                ? [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.7),
                blurRadius: 18,
                spreadRadius: 3,
              ),
            ]
                : [],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Card(
            elevation: 35,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: highlighted ? Colors.greenAccent : Colors.white,
                width: 4,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: highlighted
                    ? const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : const LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
