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
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isEmpty
            ? Colors.transparent
            : highlighted
            ? Colors.greenAccent.withOpacity(0.8)
            : Colors.blueGrey,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (highlighted)
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.7),
              blurRadius: 15,
              spreadRadius: 3,
            )
          else
            BoxShadow(
              color: Colors.black12.withOpacity(0.8),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
        ],
      ),
      alignment: Alignment.center,
      child: isEmpty
          ? const SizedBox.shrink()
          : Text(
        letter,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}