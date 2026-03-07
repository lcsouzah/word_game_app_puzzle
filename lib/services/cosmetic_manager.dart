import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/word_slide/ui/theme/board_theme.dart';


typedef HintLuminousComposer = void Function(Set<TileCoord> targets);
typedef HintSizeComposer = void Function(Set<TileCoord> targets);

@immutable
class HintEffectConfig {
  const HintEffectConfig({
    this.luminousIds = const <String>[],
    this.sizeIds = const <String>[],
  });

  final List<String> luminousIds;
  final List<String> sizeIds;

  static const HintEffectConfig classic = HintEffectConfig(
    luminousIds: <String>['innerPulse', 'letterHighlight', 'haloSoft'],
    sizeIds: <String>['scalePulse'],
  );

  /// Explicitly disables all hint visual effects.
  ///
  /// Using a concrete config instead of `null` prevents accidental fallback to
  /// [classic] in call sites that pass this value through nullable parameters.
  static const HintEffectConfig none = HintEffectConfig();
}


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
  static const String _defaultTileSkinId = 'default';
  static const String _defaultBoardSkinId = 'classic';
  static const String _defaultTrailEffectId = 'sparkle';

  String boardStyleId = BoardStyles.classicNeutral.id;
  String tileBorderStyleId = TileBorderStyles.classicOutline.id;
  String tileAnimationStyleId = TileAnimationStyles.slide.id;
  String soundPackId = 'classic';
  String hintEffectId = 'hint.inner_pulse';
  String _tileSkinId = _defaultTileSkinId;
  String _boardSkinId = _defaultBoardSkinId;
  String _trailEffectId = _defaultTrailEffectId;
  static const List<String> _defaultHintLuminousIds = <String>[
    'innerPulse',
    'letterHighlight',
    'haloSoft',
  ];
  static const List<String> _defaultHintSizeIds = <String>['scalePulse'];

  final Map<String, HintLuminousComposer> _hintLuminousRegistry =
  <String, HintLuminousComposer>{
    'innerPulse': _noopHintEffect,
    'letterHighlight': _noopHintEffect,
    'haloSoft': _noopHintEffect,
  };

  final Map<String, HintSizeComposer> _hintSizeRegistry =
  <String, HintSizeComposer>{
    'scalePulse': _noopHintEffect,
    'microBounce': _noopHintEffect,
  };

  List<String> activeHintLuminousIds =
  List<String>.from(_defaultHintLuminousIds);
  List<String> activeHintSizeIds = List<String>.from(_defaultHintSizeIds);

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
  static const Set<String> _hintConflictEffectIds = <String>{
    'glow',
    'letter_glow',
    'teleport',
    'puff',
  };

  UnmodifiableSetView<TileCoord> get hintTargets =>
      UnmodifiableSetView<TileCoord>(_hintTargets);

  BoardStyle get boardStyle => BoardStyles.byId(boardStyleId);
  TileBorderStyle get tileBorderStyle =>
      TileBorderStyles.byId(tileBorderStyleId);
  TileAnimationStyle get tileAnimationStyle =>
      TileAnimationStyles.byId(tileAnimationStyleId);
  String get tileSkin => _tileSkinId;
  String get boardSkin => _boardSkinId;
  String get trailEffect => _trailEffectId;

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
            _tileSkinId != _defaultTileSkinId ||
            _boardSkinId != _defaultBoardSkinId ||
            _trailEffectId != _defaultTrailEffectId ||
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
    _tileSkinId = _defaultTileSkinId;
    _boardSkinId = _defaultBoardSkinId;
    _trailEffectId = _defaultTrailEffectId;
    tapRippleMinimal = true;
    idleShimmerEnabled = false;
    enabledEffects.updateAll((key, value) => false);
    _hintTargets = <TileCoord>{};
    isHintActive = false;
    activeHintLuminousIds = List<String>.from(_defaultHintLuminousIds);
    activeHintSizeIds = List<String>.from(_defaultHintSizeIds);
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
    _suspendConflictingEffects(
      'hint',
      effectIds: _hintConflictEffectIds,
    );
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

  HintEffectConfig getResolvedHintConfig() {
    final List<String> luminous = activeHintLuminousIds
        .where(_hintLuminousRegistry.containsKey)
        .toList(growable: false);
    final List<String> size = activeHintSizeIds
        .where(_hintSizeRegistry.containsKey)
        .toList(growable: false);
    return HintEffectConfig(
      luminousIds: luminous.isEmpty
          ? _defaultHintLuminousIds
          : List<String>.unmodifiable(luminous),
      sizeIds: size.isEmpty
          ? _defaultHintSizeIds
          : List<String>.unmodifiable(size),
    );
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

  void setSkin(String category, String id) {
    bool changed = false;
    switch (category) {
      case 'tile':
        if (_tileSkinId != id) {
          _tileSkinId = id;
          changed = true;
        }
        break;
      case 'board':
        if (_boardSkinId != id) {
          _boardSkinId = id;
          changed = true;
        }
        break;
      case 'trail':
        if (_trailEffectId != id) {
          _trailEffectId = id;
          changed = true;
        }
        break;
      case 'sound':
        if (soundPackId != id) {
          soundPackId = id;
          changed = true;
        }
        break;
      case 'hint':
        if (hintEffectId != id) {
          hintEffectId = id;
          changed = true;
        }
        break;
      default:
        throw ArgumentError.value(
          category,
          'category',
          'Unsupported cosmetic category',
        );
    }

    if (changed) {
      notifyListeners();
    }
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

  void _suspendConflictingEffects(
      String reason, {
        Iterable<String>? effectIds,
      }) {
    // SAFETY NOTE:
    // This currently records suspensions but does not flip `enabledEffects` to
    // false. If effect toggles begin driving runtime rendering directly, add an
    // explicit suspension layer to avoid stale enabled flags bleeding into UI.
    final Iterable<MapEntry<String, bool>> entries = effectIds == null
        ? enabledEffects.entries
        : enabledEffects.entries.where(
          (entry) => effectIds.contains(entry.key),
    );
    for (final MapEntry<String, bool> entry in entries) {
      if (entry.value) {
        suspensionLog.add('suspend:${entry.key}:$reason');
      }
    }
  }

  static void _noopHintEffect(Set<TileCoord> _) {}
}