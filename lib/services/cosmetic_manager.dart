import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/word_slide/models/board_style.dart';
import 'package:word_game_app/word_slide/models/tile_animation_style.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';

@immutable
class TileCoord {
  const TileCoord(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) {
    return other is TileCoord && other.row == row && other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}

class CosmeticManager extends ChangeNotifier {
  static const String classicPresetId = 'preset.classic';

  CosmeticManager() {
    restoreClassic();
  }

  final Map<String, bool> enabledEffects = <String, bool>{
    'blink': false,
    'glow': false,
    'particles': false,
    'animated_borders': false,
    'animated_boards': false,
    'teleport': false,
    'puff': false,
    'fancy_borders': false,
    'letter_gradient': false,
    'letter_glow': false,
  };

  String activePresetId = classicPresetId;
  String boardStyleId = BoardStyles.classicNeutral.id;
  String tileBorderStyleId = TileBorderStyles.classicOutline.id;
  String tileAnimationStyleId = TileAnimationStyles.slide.id;
  String soundPackId = 'classic';
  String hintEffectId = 'hint.inner_pulse';

  Color tileColor = const Color(0xFF6B4AE2);
  Color borderColor = Colors.white;
  Color letterColor = Colors.white;
  double borderWidth = 2.0;
  bool tapRippleMinimal = true;
  bool idleShimmerEnabled = false;

  bool isPaused = false;
  bool isTutorial = false;
  bool isHintActive = false;

  Set<TileCoord> _hintTargets = <TileCoord>{};
  final List<String> suspensionLog = <String>[];

  UnmodifiableSetView<TileCoord> get hintTargets =>
      UnmodifiableSetView<TileCoord>(_hintTargets);

  BoardStyle get boardStyle => BoardStyles.byId(boardStyleId);
  TileBorderStyle get tileBorderStyle =>
      TileBorderStyles.byId(tileBorderStyleId);
  TileAnimationStyle get tileAnimationStyle =>
      TileAnimationStyles.byId(tileAnimationStyleId);

  void restoreClassic() {
    final bool hasChanged =
        activePresetId != classicPresetId ||
            boardStyleId != BoardStyles.classicNeutral.id ||
            tileBorderStyleId != TileBorderStyles.classicOutline.id ||
            tileAnimationStyleId != TileAnimationStyles.slide.id ||
            tileColor.value != const Color(0xFF6B4AE2).value ||
            borderColor.value != Colors.white.value ||
            borderWidth != 2.0 ||
            letterColor.value != Colors.white.value ||
            soundPackId != 'classic' ||
            hintEffectId != 'hint.inner_pulse' ||
            tapRippleMinimal != true ||
            idleShimmerEnabled != false ||
            isHintActive ||
            _hintTargets.isNotEmpty;

    activePresetId = classicPresetId;
    boardStyleId = BoardStyles.classicNeutral.id;
    tileBorderStyleId = TileBorderStyles.classicOutline.id;
    tileAnimationStyleId = TileAnimationStyles.slide.id;
    tileColor = const Color(0xFF6B4AE2);
    borderColor = Colors.white;
    borderWidth = 2.0;
    letterColor = Colors.white;
    soundPackId = 'classic';
    hintEffectId = 'hint.inner_pulse';
    tapRippleMinimal = true;
    idleShimmerEnabled = false;
    enabledEffects.updateAll((key, value) => false);
    _hintTargets = <TileCoord>{};
    isHintActive = false;
    _clearSuspensions();
    if (hasChanged) {
      notifyListeners();
    }
  }

  void beginHint(Set<TileCoord> targets) {
    if (targets.isEmpty) {
      return;
    }
    _hintTargets = targets;
    isHintActive = true;
    _suspendConflictingEffects('hint');
    notifyListeners();
  }

  void endHint() {
    if (!isHintActive) {
      return;
    }
    isHintActive = false;
    _hintTargets = <TileCoord>{};
    suspensionLog.add('resume:hint');
    notifyListeners();
  }

  void setPaused(bool value, {String reason = 'pause'}) {
    if (isPaused == value) {
      return;
    }
    isPaused = value;
    if (isPaused) {
      _suspendConflictingEffects(reason);
    } else {
      suspensionLog.add('resume:$reason');
    }
    notifyListeners();
  }

  void setTutorial(bool value) {
    if (isTutorial == value) {
      return;
    }
    isTutorial = value;
    if (isTutorial) {
      _suspendConflictingEffects('tutorial');
    } else {
      suspensionLog.add('resume:tutorial');
    }
    notifyListeners();
  }

  void syncFromSettings(SettingsService settings) {
    final String storedPreset = settings.activePresetId;
    final Map<String, bool> storedFlags = settings.enabledEffects;

    enabledEffects
      ..clear()
      ..addAll({
        'blink': false,
        'glow': false,
        'particles': false,
        'animated_borders': false,
        'animated_boards': false,
        'teleport': false,
        'puff': false,
        'fancy_borders': false,
        'letter_gradient': false,
        'letter_glow': false,
      })
      ..addAll(storedFlags);

    if (storedPreset != classicPresetId) {
      suspensionLog.add('preset:$storedPreset not supported -> classic');
    }
    restoreClassic();
  }

  Future<void> persistTo(SettingsService settings) {
    return settings.persistCosmeticConfig(
      presetId: activePresetId,
      enabledEffects: enabledEffects,
    );
  }

  void _clearSuspensions() {
    suspensionLog.clear();
  }

  void _suspendConflictingEffects(String reason) {
    for (final MapEntry<String, bool> entry in enabledEffects.entries) {
      if (entry.value) {
        suspensionLog.add('suspend:${entry.key}:$reason');
      }
    }
  }
}