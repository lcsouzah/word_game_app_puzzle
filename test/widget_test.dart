import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:word_game_app/main.dart';
import 'package:word_game_app/screens/mode_selection_screen.dart';

void main() {
  testWidgets('navigates from mode selection to start screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(ModeSelectionScreen), findsOneWidget);

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.text('START SCREEN'), findsOneWidget);
  });
}