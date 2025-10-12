import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralises audio and haptic feedback so screens can trigger immersive
/// responses without duplicating logic. Sound and vibration honour the current
/// user preferences supplied via [configure].
class GameFeedbackService {
  GameFeedbackService._();

  static bool _soundEnabled = true;
  static bool _hapticsEnabled = true;
  static String _activeSoundPack = 'classic';

  static final AudioPlayer _movePlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _wordPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  /// Updates the enabled state for sound/haptics as well as the active sound
  /// pack. Call this during build whenever user preferences may have changed.
  static void configure({
    bool? soundEnabled,
    bool? hapticsEnabled,
    String? soundPack,
  }) {
    if (soundEnabled != null) {
      _soundEnabled = soundEnabled;
    }
    if (hapticsEnabled != null) {
      _hapticsEnabled = hapticsEnabled;
    }
    if (soundPack != null) {
      _activeSoundPack = soundPack;
    }
  }

  /// Light feedback when a tile slides.
  static Future<void> move() async {
    if (_hapticsEnabled && defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.linux &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      unawaited(HapticFeedback.selectionClick());
    }
    if (_soundEnabled) {
      final asset = switch (_activeSoundPack) {
        'arcade' => 'sounds/tile_move1.mp3',
        'zen' => 'sounds/tile_move2.wav',
        _ => 'sounds/tile_move.mp3',
      };
      await _play(_movePlayer, asset);
    }
  }

  /// Stronger feedback used when a valid word is formed.
  static Future<void> correctWord() async {
    if (_hapticsEnabled && defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.linux &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      unawaited(HapticFeedback.mediumImpact());
    }
    if (_soundEnabled) {
      final asset = switch (_activeSoundPack) {
        'arcade' => 'sounds/tile_move2.wav',
        'zen' => 'sounds/tile_move1.mp3',
        _ => 'sounds/tile_move2.wav',
      };
      await _play(_wordPlayer, asset);
    }
  }

  static Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('⚠️ Failed to play sound $asset: $e');
    }
  }
}