import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_snake.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_grid.dart';

void main() {
  group('SerpuzzleSnake dropFirstBlankSegment', () {
    test('removes blanks without reordering collected letters', () {
      final snake = SerpuzzleSnake();

      snake.append(const GridPosition(0, 0), '');

      // Collect the first letter and expose it by moving forward twice.
      snake.append(const GridPosition(0, 1), 'A');
      snake.append(const GridPosition(0, 2), '');
      expect(snake.dropFirstBlankSegment(), isTrue);
      snake.append(const GridPosition(0, 3), '');
      expect(snake.dropFirstBlankSegment(), isTrue);

      final headIndex = snake.segments.length - 1;
      expect(headIndex, greaterThan(0));
      expect(snake.letters[headIndex - 1], 'A');

      // Collect a second letter and trim blanks created by subsequent moves.
      snake.append(const GridPosition(0, 4), 'B');
      snake.append(const GridPosition(0, 5), '');
      expect(snake.dropFirstBlankSegment(), isTrue);
      snake.append(const GridPosition(0, 6), '');
      expect(snake.dropFirstBlankSegment(), isTrue);

      final visibleLetters = [
        for (var i = 0; i < snake.segments.length - 1; i++) snake.letters[i],
      ];

      expect(visibleLetters.join(), snake.word);
    });
  });
}