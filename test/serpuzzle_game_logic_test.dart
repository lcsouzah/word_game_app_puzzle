import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app_puzzle/models/serpuzzle_grid.dart';
import 'package:word_game_app_puzzle/screens/serpuzzle_game_screen.dart';
import 'package:word_game_app_puzzle/utils/direction_enum.dart';

void main() {
  testWidgets('snake grows on letters and tail removal waits for growth',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            gridSize: 5,
            dictionary: const ['AB', 'ABC'],
            maxWordLength: 3,
          ),
        ));

        final dynamic state =
        tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();

        final initialLength = state.snake.segments.length as int;
        final GridPosition initialTail = state.snake.segments.first as GridPosition;
        final GridPosition initialHead = state.snake.segments.last as GridPosition;
        final GridPosition target =
        GridPosition(initialHead.row, initialHead.col + 1);
        expect(state.grid.inBounds(target), isTrue);

        state.grid.placeLetter(target, 'A');
        state.setCurrentTilesForTest(5);
        state.setGrowSegmentsForTest(0);
        state.setDirectionForTest(Direction.right);

        state.tickForTest();
        await tester.pump();
        state.cancelTimersForTest();

        expect(state.snake.segments.length, initialLength + 1);
        expect(state.snake.segments.contains(initialHead), isTrue);
        expect(state.snake.segments.last, equals(target));
        expect(state.grid.letterAt(target), isEmpty);
        expect(state.growSegments, equals(0));

        final GridPosition nextTarget = GridPosition(target.row, target.col + 1);
        expect(state.grid.inBounds(nextTarget), isTrue);
        state.setDirectionForTest(Direction.right);
        state.tickForTest();
        await tester.pump();
        state.cancelTimersForTest();

        expect(state.snake.segments.contains(initialTail), isFalse);
        expect(state.snake.segments.length, initialLength + 1);
        expect(state.snake.segments.last, equals(nextTarget));
        expect(state.growSegments, equals(0));
      });
}