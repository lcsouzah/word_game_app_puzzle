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

  /// Moves the current head letter (if any) onto the previous segment and
  /// clears the head entry so the head itself remains blank.
  void transferHeadLetterToPrevious() {
    if (body.length < 2) {
      return;
    }

    final headIndex = _letters.length - 1;
    final previousIndex = headIndex - 1;
    final headLetter = _letters[headIndex];
    if (headLetter.isEmpty) {
      return;
    }

    _letters[previousIndex] = headLetter;
    _letters[headIndex] = '';
  }

  /// Repositions collected letters so that they remain adjacent to the head.
  ///
  /// Any blanks that accumulate while the snake moves without collecting
  /// characters are collapsed so the oldest collected letter sits furthest
  /// from the head and the newest letter is directly behind the head.
  void alignLettersBehindHead() {
    if (_letters.isEmpty) {
      return;
    }

    final headIndex = _letters.length - 1;
    final headLetter = _letters[headIndex];
    final collected = <String>[];

    for (var i = 0; i < headIndex; i++) {
      final letter = _letters[i];
      if (letter.isNotEmpty) {
        collected.add(letter);
      }
    }

    _letters.fillRange(0, _letters.length, '');

    if (collected.isEmpty) {
      _letters[headIndex] = headLetter;
      return;
    }

    var startIndex = headIndex - collected.length;
    if (startIndex < 0) {
      startIndex = 0;
    }

    for (var i = 0; i < collected.length; i++) {
      _letters[startIndex + i] = collected[i];
    }

    _letters[headIndex] = headLetter;
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
