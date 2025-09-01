import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:word_game_app/models/alphabet_game.dart';
import 'package:word_game_app/screens/game_screen.dart';
import 'package:word_game_app/utils/pause_manager.dart';

void main() {
group('AlphabetGame tile movement', () {
test('moveTile swaps letters with empty space', () {
final game = AlphabetGame(['test']);
game.letters = [
' ', 'A', 'B', 'C',
'D', 'E', 'F', 'G',
'H', 'I', 'J', 'K',
'L', 'M', 'N', 'O'
];
game.emptyTileIndex = 0;

final moved = game.moveTile(1);
expect(moved, isTrue);
expect(game.letters[0], 'A');
expect(game.emptyTileIndex, 1);
});

test('moveTile rejects non-adjacent tile', () {
final game = AlphabetGame(['test']);
game.letters = [
' ', 'A', 'B', 'C',
'D', 'E', 'F', 'G',
'H', 'I', 'J', 'K',
'L', 'M', 'N', 'O'
];
game.emptyTileIndex = 0;

final moved = game.moveTile(5);
expect(moved, isFalse);
expect(game.emptyTileIndex, 0);
});
});

testWidgets('GameScreen enforces hint usage limit', (tester) async {
final game = AlphabetGame(['CAT']);
game.letters = [
'C','A','T','D',
'E','F','G','H',
'I','J','K','L',
'M','N','O',' '
];
game.emptyTileIndex = 15;

await tester.pumpWidget(
MaterialApp(
home: ChangeNotifierProvider(
create: (_) => PauseManager(),
child: GameScreen(
game: game,
dictionary: const ['CAT'],
onCorrectWord: (_) {},
scoringOption: ScoringOption.horizontal,
onPauseToggle: () {},
onRewardedAdRequest: () {},
maxHints: 1,
adUsesThisMatch: 0,
maxAdUsesPerMatch: 0,
),
),
),
);

final state = tester.state(find.byType(GameScreen)) as dynamic;

await tester.runAsync(() async {
await state._showHint();
await tester.pump();
});
expect(state._hintsUsed, 1);

await tester.runAsync(() async {
await state._showHint();
await tester.pump();
});
expect(state._hintsUsed, 1);
});
}