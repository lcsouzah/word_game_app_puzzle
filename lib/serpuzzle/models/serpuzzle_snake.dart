import 'package:word_game_app/serpuzzle/models/serpuzzle_grid.dart';

class SerpuzzleSnake {
  final List<GridPosition> body = [];
  final List<String> _letters = [];

  List<GridPosition> get segments => List.unmodifiable(body);

  List<String> get letters => List.unmodifiable(_letters);

  String get word => _letters.join();

  void append(GridPosition position, String letter) {
    body.add(position);
    _letters.add(letter);
  }

  /// Removes positions and letters in the range [start, end).
  void clearRange(int start, int end) {
    if (start < 0 || end > body.length || start >= end) return;
    body.removeRange(start, end);
    _letters.removeRange(start, end);
  }

  /// Drops the tail-most blank segment while keeping collected letters intact.
  ///
  /// Returns `true` when a blank segment was removed. If every segment holds a
  /// letter, the snake keeps its current length so that collected characters
  /// remain available for validation.
  bool dropFirstBlankSegment() {
    if (body.length <= 1) {
      return false;
    }

    for (var i = 0; i < body.length - 1; i++) {
      if (_letters[i].isEmpty) {
        body.removeAt(i);
        _letters.removeAt(i);
        return true;
      }
    }

    return false;
  }

  void clear() {
    body.clear();
    _letters.clear();
  }
}
