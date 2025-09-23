import 'dart:async';

import 'package:flutter/foundation.dart';

class SerpuzzleGameController extends ChangeNotifier {
  SerpuzzleGameController({
    required this.levelTimeLimit,
    required this.initialLives,
  }) : _lives = initialLives;

  final Duration levelTimeLimit;
  final int initialLives;

  Timer? _levelTimer;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  bool _isGameOver = false;
  int _score = 0;
  int _level = 1;
  int _lives;

  VoidCallback? onTimeExpired;
  VoidCallback? onGameOver;

  int get score => _score;
  int get level => _level;
  int get lives => _lives;
  Duration get elapsed => _elapsed;
  bool get isPaused => _isPaused;
  bool get isGameOver => _isGameOver;

  Duration get remainingTime {
    final remaining = levelTimeLimit - _elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get formattedRemaining {
    final remaining = remainingTime;
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void startLevelTimer({bool resetElapsed = false}) {
    _levelTimer?.cancel();
    if (resetElapsed) {
      _elapsed = Duration.zero;
      notifyListeners();
    }
    if (_isPaused || _isGameOver) {
      return;
    }
    _levelTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || _isGameOver) {
        return;
      }
      _elapsed += const Duration(seconds: 1);
      if (_elapsed >= levelTimeLimit) {
        _elapsed = levelTimeLimit;
        notifyListeners();
        _levelTimer?.cancel();
        onTimeExpired?.call();
      } else {
        notifyListeners();
      }
    });
  }

  void pause() {
    if (_isPaused) return;
    _isPaused = true;
    _levelTimer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (!_isPaused || _isGameOver) return;
    _isPaused = false;
    notifyListeners();
    startLevelTimer();
  }

  void togglePause() {
    if (_isPaused) {
      resume();
    } else {
      pause();
    }
  }

  void addScore(int amount) {
    _score += amount;
    notifyListeners();
  }

  void advanceLevel() {
    _level += 1;
    notifyListeners();
  }

  bool consumeLife() {
    if (_lives <= 1) {
      _lives = 0;
      notifyListeners();
      return false;
    }
    _lives -= 1;
    notifyListeners();
    return true;
  }

  void grantBonusLife() {
    _lives += 1;
    notifyListeners();
  }

  void resetForNewGame({bool startTimer = true}) {
    _score = 0;
    _level = 1;
    _lives = initialLives;
    _elapsed = Duration.zero;
    _isGameOver = false;
    _isPaused = false;
    notifyListeners();
    _levelTimer?.cancel();
    if (startTimer) {
      startLevelTimer(resetElapsed: true);
    }
  }

  void markGameOver() {
    if (_isGameOver) return;
    _isGameOver = true;
    _levelTimer?.cancel();
    notifyListeners();
    onGameOver?.call();
  }

  @override
  void dispose() {
    _levelTimer?.cancel();
    super.dispose();
  }
}