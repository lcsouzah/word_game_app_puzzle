//score_upload.dart

import 'package:games_services/games_services.dart';

void submitScore({
  required int score,
  required String difficulty,
}) {
  final leaderboardId = {
    'easy': 'CgkIr_H04_cJEAIQAg',
    'medium': 'CgkIr_H04_cJEAIQAw',
    'hard': 'CgkIr_H04_cJEAIQBA',
  }[difficulty];

  if (leaderboardId != null) {
    GamesServices.submitScore(
      score: Score(
      value : score,
      androidLeaderboardID: leaderboardId,
    )
    );
  }
}
