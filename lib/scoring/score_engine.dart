import '../models/difficulty.dart';

abstract class ScoreEngine {
  int calculateScore({
    required Difficulty difficulty,
    required int wordsSolved,
    required Duration timeTaken,
    required int moves,
  });
}
