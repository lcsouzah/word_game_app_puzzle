import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isMuted = false;

  // Keep track of loaded sounds
  static final Map<String, String> _loadedSounds = {};

  // Method to preload sound
  static Future<void> preloadSound(String soundId, String fileName) async {
    if (!_loadedSounds.containsKey(soundId)) {
      // Assuming you're storing these in your assets, adjust as necessary
      _loadedSounds[soundId] = fileName;
    }
  }

  // Method to play sound
  static Future<void> playSound(String soundId) async {
    if (_isMuted || !_loadedSounds.containsKey(soundId)) return;

    try {
      String fileName = _loadedSounds[soundId]!;
      await _player.setSource(AssetSource(fileName));
      await _player.resume();
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  // Toggle mute
  static void toggleMute() {
    _isMuted = !_isMuted;
  }

  // Check if muted
  static bool isMuted() {
    return _isMuted;
  }
}
