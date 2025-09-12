import '../models/serpuzzle_grid.dart';

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

  void clear() {
    body.clear();
    _letters.clear();
  }
}