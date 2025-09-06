import 'dart:math';

import 'direction_enum.dart';

class LetterUtils {
  static final Random _random = Random();

  /// Checks if placing [word] starting at ([row], [col]) in the given
  /// [direction] would overlap with different letters on [board] or exceed the
  /// board boundaries. Returns `true` if there is a conflicting overlap.
  static bool checkOverlap(
      List<List<String>> board,
      String word,
      int row,
      int col,
      Direction direction,
      ) {
    final rows = board.length;
    final cols = board.first.length;

    int dr = 0, dc = 0;
    switch (direction) {
      case Direction.up:
        dr = -1;
        break;
      case Direction.down:
        dr = 1;
        break;
      case Direction.left:
        dc = -1;
        break;
      case Direction.right:
        dc = 1;
        break;
    }

    for (var i = 0; i < word.length; i++) {
      final r = row + dr * i;
      final c = col + dc * i;
      if (r < 0 || r >= rows || c < 0 || c >= cols) {
        return true; // out of bounds treated as overlap
      }
      final existing = board[r][c];
      if (existing.isNotEmpty && existing != word[i]) {
        return true;
      }
    }
    return false;
  }

  /// Tries to place [word] on [board] at random positions and orientations.
  /// Returns `true` if the word was successfully placed without conflicts.
  static bool placeWordRandomly(
      List<List<String>> board,
      String word, {
        int maxAttempts = 100,
      }) {
    if (board.isEmpty || board.first.isEmpty) return false;
    final rows = board.length;
    final cols = board.first.length;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final direction = Direction.values[_random.nextInt(Direction.values.length)];
      final row = _random.nextInt(rows);
      final col = _random.nextInt(cols);
      if (!checkOverlap(board, word, row, col, direction)) {
        _placeWord(board, word, row, col, direction);
        return true;
      }
    }
    return false;
  }

  static void _placeWord(
      List<List<String>> board,
      String word,
      int row,
      int col,
      Direction direction,
      ) {
    int dr = 0, dc = 0;
    switch (direction) {
      case Direction.up:
        dr = -1;
        break;
      case Direction.down:
        dr = 1;
        break;
      case Direction.left:
        dc = -1;
        break;
      case Direction.right:
        dc = 1;
        break;
    }

    for (var i = 0; i < word.length; i++) {
      final r = row + dr * i;
      final c = col + dc * i;
      board[r][c] = word[i];
    }
  }
}