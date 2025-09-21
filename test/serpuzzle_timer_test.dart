import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_screen.dart';

void main() {
  testWidgets('Serpuzzle triggers game over when time expires', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SerpuzzleGameScreen(
        gridSize: 5,
        dictionary: const ['CAT'],
        maxWordLength: 3,
        levelTimeLimit: const Duration(seconds: 3),
        moveDelay: const Duration(days: 1),
      ),
    ));

    expect(find.textContaining('Time:'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Game Over'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });
}