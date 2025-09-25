import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_grid.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_screen.dart';
import 'package:word_game_app/utils/direction_enum.dart';

Future<void> _collectLetter(
    WidgetTester tester,
    dynamic state,
    String letter,
    ) async {
  final GridPosition head = state.snake.segments.last as GridPosition;
  final GridPosition target = GridPosition(head.row, head.col + 1);
  expect(state.grid.inBounds(target), isTrue);

  state.grid.placeLetter(target, letter);
  state.setCurrentTilesForTest(4);
  state.setGrowSegmentsForTest(0);
  state.setDirectionForTest(Direction.right);

  state.tickForTest();
  await tester.pump();
  state.cancelTimersForTest();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('word banner updates with progress and resets after scoring',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SerpuzzleGameScreen(
              gridSize: 5,
              dictionary: const ['AB'],
              maxWordLength: 3,
            ),
          ),
        );

        final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

        state.cancelTimersForTest();
        state.clearGridLettersForTest();

        final bannerFinder =
        find.byKey(const ValueKey('current-word-banner'));
        expect(bannerFinder, findsOneWidget);
        expect(
          find.descendant(
            of: bannerFinder,
            matching: find.text('Collect letters'),
          ),
          findsOneWidget,
        );

        await _collectLetter(tester, state, 'A');

        expect(
          find.descendant(
            of: bannerFinder,
            matching: find.text('A'),
          ),
          findsOneWidget,
        );

        await _collectLetter(tester, state, 'B');

        expect(
          find.descendant(
            of: bannerFinder,
            matching: find.text('AB'),
          ),
          findsOneWidget,
        );

        final AnimatedScale scaleWidget = tester.widget(
          find.byKey(const ValueKey('word-banner-scale')),
        );
        expect(scaleWidget.scale, greaterThan(1.0));

        // Allow the level transition dialog to appear and dismiss.
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
        state.cancelTimersForTest();
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.descendant(
            of: bannerFinder,
            matching: find.text('Collect letters'),
          ),
          findsOneWidget,
        );
      });
}