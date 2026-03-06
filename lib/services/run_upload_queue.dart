import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session.dart';
// Assume a service to interact with Google Play Games
import 'game_services_service.dart';

class RunUploadQueue {
  static const String _queueKey = 'upload_queue';
  final GameServicesService _gameServices;

  RunUploadQueue(this._gameServices);

  Future<void> queueSession(GameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode(session.toJson()));
    await prefs.setStringList(_queueKey, queue);
    // Attempt an immediate upload
    await processQueue();
  }

  Future<void> processQueue() async {
    if (!await _gameServices.isSignedIn()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];
    if (queue.isEmpty) {
      return;
    }

    final List<String> remainingQueue = [];
    for (final item in queue) {
      try {
        final session = GameSession.fromJson(jsonDecode(item));
        // In a real implementation, you would get the leaderboard ID for the session
        // and submit the score. For this example, we'll just print it.
        // final leaderboardId = LeaderboardRouter.getLeaderboardId(session.mode, session.difficulty);
        // if (leaderboardId != null) {
        //   await _gameServices.submitScore(leaderboardId, session.score);
        // } else {
        //   remainingQueue.add(item); // Keep in queue if leaderboard ID is not found
        // }
        print('Processing session: ${session.sessionId}');
      } catch (e) {
        print('Error processing session: $e');
        remainingQueue.add(item); // Keep in queue if there's an error
      }
    }

    await prefs.setStringList(_queueKey, remainingQueue);
  }
}
