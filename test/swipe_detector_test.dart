import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:word_game_app_puzzle/utils/direction_enum.dart';
import 'package:word_game_app_puzzle/utils/swipe_detector.dart';

void main() {
  testWidgets('SwipeDetector accepts light horizontal swipes', (tester) async {
    Direction? detectedDirection;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 640)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SwipeDetector(
            onSwipe: (direction) => detectedDirection = direction,
            child: const SizedBox(width: 200, height: 200),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    await gesture.moveBy(const Offset(15, 0));
    await gesture.up();
    await tester.pump();

    expect(detectedDirection, Direction.right);
  });
}