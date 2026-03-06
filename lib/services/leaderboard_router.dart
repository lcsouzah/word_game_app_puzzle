import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game_mode.dart';
import '../models/difficulty.dart';

class LeaderboardRouter {
  static String? getLeaderboardId(GameMode mode, Difficulty difficulty) {
    if (mode == GameMode.wordSlide) {
      switch (difficulty) {
        case Difficulty.easy:
          return dotenv.env['LEADERBOARD_ID_EASY'];
        case Difficulty.medium:
          return dotenv.env['LEADERBOARD_ID_MEDIUM'];
        case Difficulty.hard:
          return dotenv.env['LEADERBOARD_ID_HARD'];
      }
    } else if (mode == GameMode.serpuzzle) {
      // Future: Use separate IDs for Serpuzzle
      switch (difficulty) {
        case Difficulty.easy:
          return dotenv.env['SERPUZZLE_LEADERBOARD_ID_EASY'];
        case Difficulty.medium:
          return dotenv.env['SERPUZZLE_LEADERBOARD_ID_MEDIUM'];
        case Difficulty.hard:
          return dotenv.env['SERPUZZLE_LEADERBOARD_ID_HARD'];
      }
    }
    return null;
  }
}
