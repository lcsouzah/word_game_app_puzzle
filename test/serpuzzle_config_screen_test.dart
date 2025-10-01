import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_config_screen.dart';

void main() {
  testWidgets('Serpuzzle switches use configured thumb and track colors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SerpuzzleConfigScreen()));

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(2));

    for (final toggle in switches) {
      expect(toggle.activeThumbColor, Colors.blueGrey.shade900);
      expect(toggle.inactiveThumbColor, Colors.white);
      expect(toggle.activeTrackColor, Colors.greenAccent.shade200);
      expect(toggle.inactiveTrackColor, Colors.blueGrey.shade300);
    }
  });
}