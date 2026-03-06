import 'dart:math';
import 'score_engine.dart';
import '../models/difficulty.dart';

class SerpuzzleScoreEngine implements ScoreEngine {
  @override
  int calculateScore({
    required Difficulty difficulty,
    required int wordsSolved,
    required Duration timeTaken,
    required int moves, // Represents words chained in this context
  }) {
    final double difficultyMultiplier = _getDifficultyMultiplier(difficulty);
    final int baseScore = wordsSolved * 50; // Base score per word
    final int comboBonus = max(0, moves - 1) * 25; // Bonus for chaining words

    return ((baseScore + comboBonus) * difficultyMultiplier).clamp(0, 9999999).toInt();
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
