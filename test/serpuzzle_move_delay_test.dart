import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/serpuzzle/models/difficulty_level.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_config_screen.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_screen.dart';

void main() {
  Future<Duration> _launchWithDifficulty(
      WidgetTester tester,
      DifficultyLevel level,
      ) async {
    if (level != DifficultyLevel.easy) {
      await tester.tap(find.byType(DropdownButton<DifficultyLevel>));
      await tester.pumpAndSettle();
      final label = switch (level) {
        DifficultyLevel.easy => 'Easy',
        DifficultyLevel.moderate => 'Moderate',
        DifficultyLevel.hard => 'Hard',
      };
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    final gameFinder = find.byType(SerpuzzleGameScreen);
    expect(gameFinder, findsOneWidget);

    final dynamic state = tester.state(gameFinder);
    final Duration delay = state.moveDelayForTest as Duration;
    state.cancelTimersForTest();

    Navigator.of(tester.element(gameFinder)).pop();
    await tester.pumpAndSettle();

    return delay;
  }

  testWidgets('Serpuzzle timer delay varies by difficulty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SerpuzzleConfigScreen()));

    final easyDelay = await _launchWithDifficulty(tester, DifficultyLevel.easy);
    final moderateDelay =
    await _launchWithDifficulty(tester, DifficultyLevel.moderate);
    final hardDelay = await _launchWithDifficulty(tester, DifficultyLevel.hard);

    expect(easyDelay, greaterThan(moderateDelay));
    expect(moderateDelay, greaterThanOrEqualTo(hardDelay));
  });
}