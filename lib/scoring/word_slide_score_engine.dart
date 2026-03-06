import 'dart:math';
import 'score_engine.dart';
import '../models/difficulty.dart';

class WordSlideScoreEngine implements ScoreEngine {
  @override
  int calculateScore({
    required Difficulty difficulty,
    required int wordsSolved,
    required Duration timeTaken,
    required int moves,
  }) {
    final double difficultyMultiplier = _getDifficultyMultiplier(difficulty);
    final int baseScore = wordsSolved * 100;
    final int timeBonus = max(0, 120 - timeTaken.inSeconds) * 10;
    final int movePenalty = moves * 5;

    return ((baseScore + timeBonus - movePenalty) * difficultyMultiplier).clamp(0, 9999999).toInt();
  }

  double _getDifficultyMultiplier(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 1.0;
      case Difficulty.medium:
        return 1.5;
      case Difficulty.hard:
        return 2.0;
    }
  }
}
