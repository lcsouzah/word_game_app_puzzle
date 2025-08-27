import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/utils/pause_manager.dart';

void main() {
  test('pause and resume only for matching reason', () {
    final manager = PauseManager();
    manager.pause(PauseReason.manual);
    expect(manager.isPaused, isTrue);

    manager.resume(PauseReason.hint);
    expect(manager.isPaused, isTrue);

    manager.resume(PauseReason.manual);
    expect(manager.isPaused, isFalse);
  });

  test('forceResume clears any pause', () {
    final manager = PauseManager();
    manager.pause(PauseReason.ad);
    expect(manager.isPaused, isTrue);

    manager.forceResume();
    expect(manager.isPaused, isFalse);
  });
}