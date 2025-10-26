import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralises audio and haptic feedback so screens can trigger immersive
/// responses without duplicating logic. Sound and vibration honour the current
/// user preferences supplied via [configure].
enum MoveHapticIntensity { light, medium }

enum SuccessHapticIntensity { medium, heavy }

class GameFeedbackService {
  GameFeedbackService._();

  static bool _soundEnabled = true;
  static bool _hapticsEnabled = true;
  static String _activeSoundPack = 'classic';
  static MoveHapticIntensity _moveHapticIntensity =
      MoveHapticIntensity.light;
  static SuccessHapticIntensity _successHapticIntensity =
      SuccessHapticIntensity.medium;
  static DateTime? _lastMoveHapticTime;

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
    MoveHapticIntensity? moveHapticIntensity,
    SuccessHapticIntensity? successHapticIntensity,
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
    if (moveHapticIntensity != null) {
      _moveHapticIntensity = moveHapticIntensity;
    }
    if (successHapticIntensity != null) {
      _successHapticIntensity = successHapticIntensity;
    }
  }

  /// Light feedback when a tile slides.
  static Future<void> onTileMove() async {
    _triggerMoveHaptic();
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
  static Future<void> onCorrectWord() async {
    _triggerSuccessHaptic();
    if (_soundEnabled) {
      final asset = switch (_activeSoundPack) {
        'arcade' => 'sounds/tile_move2.wav',
        'zen' => 'sounds/tile_move1.mp3',
        _ => 'sounds/tile_move2.wav',
      };
      await _play(_wordPlayer, asset);
    }
  }

  static void _triggerMoveHaptic() {
    if (!_canVibrate) return;
    final now = DateTime.now();
    final last = _lastMoveHapticTime;
    if (last != null && now.difference(last) < const Duration(milliseconds: 120)) {
      return;
    }
    _lastMoveHapticTime = now;
    switch (_moveHapticIntensity) {
      case MoveHapticIntensity.light:
        unawaited(HapticFeedback.selectionClick());
        break;
      case MoveHapticIntensity.medium:
        unawaited(HapticFeedback.lightImpact());
        break;
    }
  }

  static void _triggerSuccessHaptic() {
    if (!_canVibrate) return;
    switch (_successHapticIntensity) {
      case SuccessHapticIntensity.medium:
        unawaited(HapticFeedback.mediumImpact());
        break;
      case SuccessHapticIntensity.heavy:
        unawaited(HapticFeedback.heavyImpact());
        break;
    }
  }

  static bool get _canVibrate {
    if (!_hapticsEnabled) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return true;
      default:
        return false;
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