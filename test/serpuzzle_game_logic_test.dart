import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/serpuzzle/models/difficulty_level.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_grid.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_screen.dart';
import 'package:word_game_app/utils/direction_enum.dart';

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

  testWidgets('consumed letters shift behind head immediately', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SerpuzzleGameScreen(
        gridSize: 5,
        dictionary: const ['AB'],
        maxWordLength: 3,
      ),
    ));

    final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

    state.cancelTimersForTest();
    state.clearGridLettersForTest();

    final GridPosition head = state.snake.segments.last as GridPosition;
    final GridPosition target = GridPosition(head.row, head.col + 1);
    expect(state.grid.inBounds(target), isTrue);

    state.grid.placeLetter(target, 'A');
    state.setCurrentTilesForTest(4);
    state.setGrowSegmentsForTest(0);
    state.setDirectionForTest(Direction.right);

    state.tickForTest();
    await tester.pump();
    state.cancelTimersForTest();

    final letters = List<String>.from(state.snake.letters);
    expect(letters.length, greaterThan(1));
    expect(letters.last, isEmpty);
    expect(letters[letters.length - 2], equals('A'));

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('letters realign behind head after empty moves', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SerpuzzleGameScreen(
        gridSize: 7,
        dictionary: const ['AB'],
        maxWordLength: 3,
      ),
    ));

    final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

    state.cancelTimersForTest();
    state.clearGridLettersForTest();

    final collected = <String>['A', 'B'];

    for (final letter in collected) {
      final head = state.snake.segments.last as GridPosition;
      final target = GridPosition(head.row, head.col + 1);
      expect(state.grid.inBounds(target), isTrue);

      state.grid.placeLetter(target, letter);
      state.setCurrentTilesForTest(5);
      state.setGrowSegmentsForTest(0);
      state.setDirectionForTest(Direction.right);

      state.tickForTest();
      await tester.pump();
      state.cancelTimersForTest();
    }

    final headAfterCollect = state.snake.segments.last as GridPosition;
    final emptyTarget =
    GridPosition(headAfterCollect.row, headAfterCollect.col + 1);
    expect(state.grid.inBounds(emptyTarget), isTrue);

    state.setDirectionForTest(Direction.right);
    state.setGrowSegmentsForTest(0);
    state.tickForTest();
    await tester.pump();
    state.cancelTimersForTest();

    final lettersList = List<String>.from(state.snake.letters);
    final headIndex = lettersList.length - 1;
    final startIndex = headIndex - collected.length;

    expect(lettersList.length, greaterThan(collected.length));
    expect(startIndex, greaterThanOrEqualTo(0));
    expect(state.snake.word, equals(collected.join()));
    expect(
      lettersList.sublist(startIndex, headIndex).join(),
      equals(collected.join()),
    );
    expect(headIndex, greaterThan(0));
    expect(lettersList[headIndex - 1], equals(collected.last));
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

  testWidgets('prefix failure deducts lives and triggers game over at zero',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            gridSize: 5,
            dictionary: const ['DOG'],
            maxWordLength: 3,
          ),
        ));

        final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();

        expect(state.livesForTest, equals(3));
        expect(find.text('Lives: 3'), findsOneWidget);

        Future<GridPosition> feedWrongLetter() async {
          final GridPosition head = state.snake.segments.last as GridPosition;
          final candidates = <Direction, GridPosition>{
            Direction.right: GridPosition(head.row, head.col + 1),
            Direction.down: GridPosition(head.row + 1, head.col),
            Direction.left: GridPosition(head.row, head.col - 1),
            Direction.up: GridPosition(head.row - 1, head.col),
          };

          for (final entry in candidates.entries) {
            final candidate = entry.value;
            if (state.grid.inBounds(candidate)) {
              state.grid.placeLetter(candidate, 'Z');
              state.setCurrentTilesForTest(1);
              state.setDirectionForTest(entry.key);
              state.tickForTest();
              await tester.pump();
              state.cancelTimersForTest();
              return candidate;
            }
          }

          throw StateError('No in-bounds move available');
        }

        final firstTarget = await feedWrongLetter();
        expect(state.livesForTest, equals(2));
        expect(find.text('Lives: 2'), findsOneWidget);
        expect(state.snake.segments.length, equals(1));
        expect(state.snake.segments.last, equals(firstTarget));

        state.clearGridLettersForTest();

        final secondTarget = await feedWrongLetter();
        expect(state.livesForTest, equals(1));
        expect(find.text('Lives: 1'), findsOneWidget);
        expect(state.snake.segments.last, equals(secondTarget));

        state.clearGridLettersForTest();

        await feedWrongLetter();
        await tester.pump();

        expect(state.livesForTest, equals(0));
        expect(state.isGameOverForTest, isTrue);
        expect(find.text('Lives: 0'), findsOneWidget);
        expect(find.text('Game Over'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
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
  testWidgets('collisions consume lives before triggering game over',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            gridSize: 5,
            dictionary: const ['CAT'],
            maxWordLength: 3,
            difficulty: DifficultyLevel.moderate,
          ),
        ));

        final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));
        state.cancelTimersForTest();

        Future<void> collideWithWall() async {
          state.clearGridLettersForTest();
          state.setGrowSegmentsForTest(0);
          final GridPosition head = state.snake.segments.last as GridPosition;
          final int stepsToBoundary = head.col + 1;
          state.setDirectionForTest(Direction.left);
          for (var i = 0; i < stepsToBoundary; i++) {
            state.tickForTest();
            await tester.pump();
          }
        }

        expect(state.livesForTest, equals(2));

        await collideWithWall();
        await tester.pump();
        expect(state.livesForTest, equals(1));
        expect(state.isGameOverForTest, isFalse);

        await collideWithWall();
        await tester.pump();
        expect(state.livesForTest, equals(0));
        expect(state.isGameOverForTest, isTrue);
        expect(find.text('Game Over'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      });
}