import '../models/serpuzzle_grid.dart';

class SerpuzzleSnake {
  final List<GridPosition> body = [];
  final StringBuffer _letters = StringBuffer();

  List<GridPosition> get segments => List.unmodifiable(body);

  String get word => _letters.toString();

  void append(GridPosition position, String letter) {
    body.add(position);
    _letters.write(letter);
  }

  /// Removes positions and letters in the range [start, end).
  void clearRange(int start, int end) {
    if (start < 0 || end > body.length || start >= end) return;
    body.removeRange(start, end);
    final current = _letters.toString();
    _letters
      ..clear()
      ..write(current.substring(0, start) + current.substring(end));
  }

  void clear() {
    body.clear();
    _letters.clear();
  }
}