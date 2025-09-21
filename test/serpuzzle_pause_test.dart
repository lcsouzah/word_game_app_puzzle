import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_grid.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_screen.dart';
import 'package:word_game_app/utils/direction_enum.dart';

void main() {
  testWidgets('pausing stops the snake until play is resumed', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SerpuzzleGameScreen(
        gridSize: 5,
        dictionary: const ['AA'],
        maxWordLength: 3,
      ),
    ));

    final dynamic state = tester.state(find.byType(SerpuzzleGameScreen));

    state.cancelTimersForTest();
    state.clearGridLettersForTest();
    state.setDirectionForTest(Direction.right);

    final GridPosition initialHead = state.snake.segments.last as GridPosition;

    state.tickForTest();
    await tester.pump();

    final GridPosition advancedHead = state.snake.segments.last as GridPosition;
    expect(advancedHead.col, initialHead.col + 1);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    state.tickForTest();
    await tester.pump();

    final GridPosition pausedHead = state.snake.segments.last as GridPosition;
    expect(pausedHead, equals(advancedHead));

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    state.tickForTest();
    await tester.pump();
    state.cancelTimersForTest();

    final GridPosition resumedHead = state.snake.segments.last as GridPosition;
    expect(resumedHead.col, advancedHead.col + 1);
  });
}