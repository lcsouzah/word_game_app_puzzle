import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:word_game_app/serpuzzle/widgets/serpuzzle_snake_head.dart';

void main() {
  testWidgets('Serpuzzle snake head renders orientation cues', (tester) async {
    const tileSize = 64.0;
    const key = ValueKey('serpuzzle-heads');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: SnakeDirection.values.map((direction) {
                    final highlighted = direction == SnakeDirection.up ||
                        direction == SnakeDirection.left;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: tileSize,
                        height: tileSize,
                        child: SerpuzzleSnakeHead(
                          direction: direction,
                          highlighted: highlighted,
                          tileSize: tileSize,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/serpuzzle_snake_head'),
    );
  });
}