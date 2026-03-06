import 'package:uuid/uuid.dart';
import 'game_mode.dart';
import 'difficulty.dart';

class GameSession {
  final String sessionId;
  final GameMode mode;
  final Difficulty difficulty;
  final DateTime startTime;
  final DateTime endTime;
  final int moves;
  final int words;
  final int score;
  final int? seed;

  GameSession({
    required this.mode,
    required this.difficulty,
    required this.startTime,
    required this.endTime,
    required this.moves,
    required this.words,
    required this.score,
    this.seed,
  }) : sessionId = const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'mode': mode.toString(),
        'difficulty': difficulty.toString(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'moves': moves,
        'words': words,
        'score': score,
        'seed': seed,
      };

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
        mode: GameMode.values.firstWhere((e) => e.toString() == json['mode']),
        difficulty: Difficulty.values.firstWhere((e) => e.toString() == json['difficulty']),
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        moves: json['moves'],
        words: json['words'],
        score: json['score'],
        seed: json['seed'],
      );
  }
}
