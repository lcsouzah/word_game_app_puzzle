import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/serpuzzle/widgets/serpuzzle_snake_body.dart';
import 'package:word_game_app/serpuzzle/widgets/serpuzzle_snake_head.dart';
import 'package:word_game_app/serpuzzle/widgets/serpuzzle_snake_segment_tile.dart';

void main() {
  testWidgets('SerpuzzleSnakeBody keeps scaled segments centered in their tiles',
          (tester) async {
        const tileSize = 40.0;
        const segmentScale = 0.75;
        const segmentSize = tileSize * segmentScale;
        const offset = (tileSize - segmentSize) / 2;

        const segments = [
          SnakeSegment(row: 0, col: 0, letter: 'A'),
          SnakeSegment(row: 0, col: 1),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: tileSize * 2,
                  height: tileSize,
                  child: SerpuzzleSnakeBody(
                    segments: segments,
                    tileSize: tileSize,
                    segmentScale: segmentScale,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final bodyRect = tester.getRect(find.byType(SerpuzzleSnakeSegmentTile));
        final headRect = tester.getRect(find.byType(SerpuzzleSnakeHead));

        expect(bodyRect.width, closeTo(segmentSize, 0.01));
        expect(bodyRect.height, closeTo(segmentSize, 0.01));
        expect(bodyRect.left, closeTo(offset, 0.01));
        expect(bodyRect.top, closeTo(offset, 0.01));
        expect(bodyRect.right, closeTo(tileSize - offset, 0.01));
        expect(bodyRect.bottom, closeTo(tileSize - offset, 0.01));

        expect(headRect.width, closeTo(segmentSize, 0.01));
        expect(headRect.height, closeTo(segmentSize, 0.01));
        expect(headRect.left, closeTo(tileSize + offset, 0.01));
        expect(headRect.top, closeTo(offset, 0.01));
        expect(headRect.right, closeTo(tileSize * 2 - offset, 0.01));
        expect(headRect.bottom, closeTo(tileSize - offset, 0.01));
          });
}