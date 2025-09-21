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
  
  testWidgets('snake trims only overflow segments when exceeding max word',
          (tester) async {
            await tester.pumpWidget(MaterialApp(
                  home: SerpuzzleGameScreen(
                        gridSize: 8,
                        dictionary: const ['ABCD'],
                        maxWordLength: 3,
                  ),
            ));

            final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

            state.cancelTimersForTest();
            state.clearGridLettersForTest();

            final GridPosition head = state.snake.segments.last as GridPosition;
            final List<GridPosition> path = List.generate(
                  4,
                      (index) => GridPosition(head.row, head.col + index + 1),
            );

            for (final target in path) {
                  expect(state.grid.inBounds(target), isTrue);
            }

            const letters = ['A', 'B', 'C', 'D'];

            state.setDirectionForTest(Direction.right);

            for (var i = 0; i < path.length; i++) {
              final target = path[i];
              state.grid.placeLetter(target, letters[i]);
              state.setCurrentTilesForTest(5);
              state.tickForTest();
              await tester.pump();
              state.cancelTimersForTest();
            }

            expect(state.snake.word.length, equals(3));
            expect(state.snake.word, equals('BCD'));
            expect(state.snake.segments.length, greaterThan(1));
            expect(state.snake.segments.last, equals(path.last));
          });

  testWidgets('spawnRandomTiles honors requested count and preserves letters',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            gridSize: 7,
            dictionary: const ['A', 'DOG', 'CAT'],
            maxWordLength: 4,
          ),
        ));

        final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();

        state.spawnRandomTilesForTest(2);

        final grid = state.grid as SerpuzzleGrid;

        int letterCount = 0;
        for (var i = 0; i < grid.length; i++) {
          final pos = grid.positionOfIndex(i);
          if (grid.letterAt(pos).isNotEmpty) {
            letterCount++;
          }
        }

        expect(letterCount, 2);
        expect(state.currentTilesForTest, 2);

        state.spawnRandomTilesForTest(1);

        int updatedCount = 0;
        for (var i = 0; i < grid.length; i++) {
          final pos = grid.positionOfIndex(i);
          if (grid.letterAt(pos).isNotEmpty) {
            updatedCount++;
          }
        }

        expect(updatedCount, 3);
        expect(state.currentTilesForTest, 3);
      });

  testWidgets('spawnRandomTiles keeps distance from the snake body',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            gridSize: 7,
            dictionary: const ['DOG', 'CAT', 'BEE'],
            maxWordLength: 4,
          ),
        ));

        final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();

        state.spawnRandomTilesForTest(3);

        final grid = state.grid as SerpuzzleGrid;
        final List<GridPosition> snakeSegments =
        List<GridPosition>.from(state.snake.segments as Iterable);
        final minDistance = state.minSpawnDistanceForTest as int;

        int separatedTiles = 0;
        for (var i = 0; i < grid.length; i++) {
          final pos = grid.positionOfIndex(i);
          final letter = grid.letterAt(pos);
          if (letter.isEmpty) continue;

          separatedTiles++;
          for (final segment in snakeSegments) {
            final distance =
                (pos.row - segment.row).abs() + (pos.col - segment.col).abs();
            expect(
              distance >= minDistance,
              isTrue,
              reason: 'Tile at ${pos.row},${pos.col} too close to snake',
            );
          }
        }

        expect(separatedTiles, 3);
      });
  testWidgets('snake wraps across all edges when wrapAround is enabled',
          (tester) async {
        const gridSize = 5;
        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            gridSize: gridSize,
            dictionary: const ['A'],
            maxWordLength: 3,
            wrapAround: true,
          ),
        ));

        final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();
        state.setGrowSegmentsForTest(0);

        Future<void> move(Direction direction) async {
          state.setDirectionForTest(direction);
          state.tickForTest();
          await tester.pump();
          state.cancelTimersForTest();
        }

        GridPosition head = state.snake.segments.last as GridPosition;
        final int initialRow = head.row;
        final int stepsToLeftBoundary = head.col + 1;
        for (var i = 0; i < stepsToLeftBoundary; i++) {
          await move(Direction.left);
        }
        head = state.snake.segments.last as GridPosition;
        expect(head.row, equals(initialRow));
        expect(head.col, equals(gridSize - 1));
        expect(state.isGameOverForTest, isFalse);

        await move(Direction.right);
        head = state.snake.segments.last as GridPosition;
        expect(head.col, equals(0));
        expect(head.row, equals(initialRow));
        expect(state.isGameOverForTest, isFalse);

        final int stepsToTopBoundary = head.row + 1;
        for (var i = 0; i < stepsToTopBoundary; i++) {
          await move(Direction.up);
        }
        head = state.snake.segments.last as GridPosition;
        expect(head.row, equals(gridSize - 1));
        expect(head.col, equals(0));
        expect(state.isGameOverForTest, isFalse);

        await move(Direction.down);
        head = state.snake.segments.last as GridPosition;
        expect(head.row, equals(0));
        expect(head.col, equals(0));
        expect(state.isGameOverForTest, isFalse);
      });
}