// Y:\word_game_app_puzzle\lib\utils\pause_manager.dart

import 'package:flutter/foundation.dart';


enum PauseReason{
  none, //Game running
  manual, //user pressed pause button
  hint, // Game paused to show hint
  ad, // Game paused to show ad
}



class PauseManager extends ChangeNotifier{
  PauseReason _pauseReason = PauseReason.none;

  PauseReason get pauseReason => _pauseReason;
  bool get isPaused => _pauseReason != PauseReason.none;

  void pause(PauseReason reason){
    _pauseReason = reason;
    notifyListeners();
  }

  void resume(PauseReason reason) {
    // Only resume if the same reason triggered the pause
    if (_pauseReason == reason) {
      _pauseReason = PauseReason.none;
      notifyListeners();
    }


  }

  void forceResume() {
    //Force resume regardless of reason
    _pauseReason = PauseReason.none;
    notifyListeners();
  }

}