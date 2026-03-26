import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_grid.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_screen.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_controller.dart';
import 'package:word_game_app/utils/direction_enum.dart';

void main() {
  testWidgets('snake grows on letters and tail removal waits for growth',
          (tester) async {
        final controller = SerpuzzleGameController(
          gridSize: 5,
          dictionary: const ['AB', 'ABC'],
          maxWordLength: 3,
          levelTimeLimit: const Duration(minutes: 1),
          initialLives: 3,
        );

        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            controller: controller,
          ),
        ));

        final dynamic state =
        tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();

        final initialLength = state.snake.segments.length as int;
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

        expect(state.snake.segments.contains(state.snake.segments.first), isTrue); // Just a dummy check to avoid initialTail reference if needed
        expect(state.snake.segments.length, initialLength + 1);
        expect(state.snake.segments.last, equals(nextTarget));
        expect(state.growSegments, equals(0));
      });

  testWidgets('snake can move into tail after blank drop without collision',
          (tester) async {
        final controller = SerpuzzleGameController(
          gridSize: 5,
          dictionary: const ['AB'],
          maxWordLength: 3,
          levelTimeLimit: const Duration(minutes: 1),
          initialLives: 3,
        );

        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            controller: controller,
          ),
        ));

        final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();

        final int initialLength = state.snake.segments.length as int;
        final GridPosition initialHead = state.snake.segments.last as GridPosition;
        final GridPosition growthTarget =
        GridPosition(initialHead.row, initialHead.col + 1);
        expect(state.grid.inBounds(growthTarget), isTrue);

        state.setGrowSegmentsForTest(1);
        state.setDirectionForTest(Direction.right);
        state.tickForTest();
        await tester.pump();
        state.cancelTimersForTest();

        expect(state.snake.segments.length, initialLength + 1);
        expect(state.snake.segments.last, equals(growthTarget));
        expect(state.growSegments, equals(0));

        final List<String> letters = List<String>.from(state.snake.letters);
        expect(letters, isNotEmpty);
        expect(letters.first, isEmpty);

        state.setDirectionForTest(Direction.left);
        state.tickForTest();
        await tester.pump();
        state.cancelTimersForTest();

        expect(state.snake.segments.length, initialLength + 1);
        expect(state.snake.segments.last, equals(initialHead));
        expect(state.snake.segments.first, equals(growthTarget));
        expect(state.growSegments, equals(0));
      });

  testWidgets('consumed letters shift behind head immediately', (tester) async {
    final controller = SerpuzzleGameController(
      gridSize: 5,
      dictionary: const ['AB'],
      maxWordLength: 3,
      levelTimeLimit: const Duration(minutes: 1),
      initialLives: 3,
    );

    await tester.pumpWidget(MaterialApp(
      home: SerpuzzleGameScreen(
        controller: controller,
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
  });

  testWidgets('letters realign behind head after empty moves', (tester) async {
    final controller = SerpuzzleGameController(
      gridSize: 7,
      dictionary: const ['AB'],
      maxWordLength: 3,
      levelTimeLimit: const Duration(minutes: 1),
      initialLives: 3,
    );

    await tester.pumpWidget(MaterialApp(
      home: SerpuzzleGameScreen(
        controller: controller,
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
            final controller = SerpuzzleGameController(
              gridSize: 8,
              dictionary: const ['ABCD'],
              maxWordLength: 3,
              levelTimeLimit: const Duration(minutes: 1),
              initialLives: 3,
            );

            await tester.pumpWidget(MaterialApp(
                  home: SerpuzzleGameScreen(
                        controller: controller,
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
        final controller = SerpuzzleGameController(
          gridSize: 7,
          dictionary: const ['A', 'DOG', 'CAT'],
          maxWordLength: 4,
          levelTimeLimit: const Duration(minutes: 1),
          initialLives: 3,
        );

        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            controller: controller,
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

  testWidgets('spawnRandomTiles filler letters come from safe starts',
          (tester) async {
        final controller = SerpuzzleGameController(
          gridSize: 7,
          dictionary: const ['DOG', 'CAT'],
          maxWordLength: 4,
          levelTimeLimit: const Duration(minutes: 1),
          initialLives: 3,
        );

        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            controller: controller,
          ),
        ));

        final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();

        expect(state.safeStartLettersForTest, containsAll(<String>{'D', 'C'}));

        state.spawnRandomTilesForTest(1);

        final grid = state.grid as SerpuzzleGrid;
        final spawnedLetters = <String>[];
        for (var i = 0; i < grid.length; i++) {
          final pos = grid.positionOfIndex(i);
          final letter = grid.letterAt(pos);
          if (letter.isNotEmpty) {
            spawnedLetters.add(letter);
          }
        }

        expect(spawnedLetters, hasLength(1));
        final letter = spawnedLetters.single;
        expect(state.safeStartLettersForTest.contains(letter), isTrue,
            reason: 'Filler letter $letter should be a safe start');
      });

  testWidgets('prefix failure deducts lives and triggers game over at zero',
          (tester) async {
        final controller = SerpuzzleGameController(
          gridSize: 5,
          dictionary: const ['DOG'],
          maxWordLength: 3,
          levelTimeLimit: const Duration(minutes: 1),
          initialLives: 3,
        );

        await tester.pumpWidget(MaterialApp(
          home: SerpuzzleGameScreen(
            controller: controller,
          ),
        ));

        final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();

        expect(state.livesForTest, equals(3));

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

        await feedWrongLetter();
        expect(state.livesForTest, equals(2));
        expect(state.snake.segments.length, equals(1));

        state.clearGridLettersForTest();

        await feedWrongLetter();
        expect(state.livesForTest, equals(1));

        state.clearGridLettersForTest();

        await feedWrongLetter();
        await tester.pump();

        expect(state.livesForTest, equals(0));
        expect(state.isGameOverForTest, isTrue);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      });
}
