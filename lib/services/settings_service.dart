import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_game_app/services/game_feedback_service.dart';
import 'package:word_game_app/word_slide/models/board_style.dart';
import 'package:word_game_app/word_slide/models/tile_animation_style.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';

/// Provides persisted user settings for tile appearance, feedback and
/// performance behaviour across the puzzle experience.
class SettingsService extends ChangeNotifier {
  static const _tileColorKey = 'tileColor';
  static const _borderStyleKey = 'borderStyle';
  static const _borderColorKey = 'borderColor';
  static const _borderAssetPathKey = 'borderAssetPath';
  static const _boardStyleKey = 'boardStyle';
  static const _tileAnimationStyleKey = 'tileAnimationStyle';
  static const _soundEnabledKey = 'soundEnabled';
  static const _hapticsEnabledKey = 'hapticsEnabled';
  static const _titleCaseKey = 'titleCaseWords';
  static const _soundPackKey = 'soundPack';
  static const _moveHapticIntensityKey = 'moveHapticIntensity';
  static const _successHapticIntensityKey = 'successHapticIntensity';
  static const _hintEffectKey = 'hintEffect';
  static const _showHintTrailKey = 'showHintTrail';
  static const _animatedBackgroundKey = 'animatedBackground';
  static const _idleShimmerKey = 'idleShimmer';
  static const _devUnlockPremiumKey = 'devUnlockPremiumCosmetics';
  static const _activeCosmeticPresetKey = 'activeCosmeticPreset';
  static const _enabledEffectsKey = 'enabledCosmeticEffects';

  static const Map<String, bool> _baselineEffectFlags = <String, bool>{
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

  Color _tileColor = const Color(0xFF6B4AE2);
  Color _borderColor = Colors.white;
  String _borderStyleId = TileBorderStyles.classicOutline.id;
  String _boardStyleId = BoardStyles.classicNeutral.id;
  String _tileAnimationStyleId = TileAnimationStyles.defaultStyle.id;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _useTitleCaseWords = true;
  String _soundPack = 'classic';
  MoveHapticIntensity _moveHapticIntensity = MoveHapticIntensity.light;
  SuccessHapticIntensity _successHapticIntensity =
      SuccessHapticIntensity.medium;
  String _hintEffect = 'hint.inner_pulse';
  bool _showHintTrail = false;
  bool _animatedBackground = false;
  bool _idleShimmer = false;
  bool _devUnlockPremiumCosmetics = false;
  String _activePresetId = 'preset.classic';
  Map<String, bool> _enabledEffects =
  Map<String, bool>.from(_baselineEffectFlags);

  /// Current color used for puzzle tiles.
  Color get tileColor => _tileColor;

  /// Current color used for puzzle borders.
  Color get borderColor => _borderColor;

  /// Currently selected border style.
  TileBorderStyle get borderStyle => TileBorderStyles.byId(_borderStyleId);

  /// Currently selected board style.
  BoardStyle get boardStyle => BoardStyles.byId(_boardStyleId);

  /// Currently selected tile animation style.
  TileAnimationStyle get tileAnimationStyle =>
      TileAnimationStyles.byId(_tileAnimationStyleId);

  bool get soundEnabled => _soundEnabled;

  bool get hapticsEnabled => _hapticsEnabled;

  bool get useTitleCaseWords => _useTitleCaseWords;

  String get soundPack => _soundPack;

  MoveHapticIntensity get moveHapticIntensity => _moveHapticIntensity;

  SuccessHapticIntensity get successHapticIntensity =>
      _successHapticIntensity;

  String get hintEffect => _hintEffect;

  bool get showHintTrail => _showHintTrail;

  bool get animatedBackgroundEnabled => _animatedBackground;

  bool get idleShimmerEnabled => _idleShimmer;

  bool get devUnlockPremiumCosmetics => _devUnlockPremiumCosmetics;

  String get activePresetId => _activePresetId;

  Map<String, bool> get enabledEffects =>
      Map<String, bool>.unmodifiable(_enabledEffects);

  /// Loads previously saved settings from [SharedPreferences].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_tileColorKey);
    final borderStyleId = prefs.getString(_borderStyleKey);
    final borderColorValue = prefs.getInt(_borderColorKey);
    final boardStyleId = prefs.getString(_boardStyleKey);
    final tileAnimationStyleId = prefs.getString(_tileAnimationStyleKey);
    final soundEnabled = prefs.getBool(_soundEnabledKey);
    final hapticsEnabled = prefs.getBool(_hapticsEnabledKey);
    final titleCasePref = prefs.getBool(_titleCaseKey);
    final soundPackPref = prefs.getString(_soundPackKey);
    final moveIntensityPref = prefs.getString(_moveHapticIntensityKey);
    final successIntensityPref =
    prefs.getString(_successHapticIntensityKey);
    final hintEffectPref = prefs.getString(_hintEffectKey);
    final hintTrailPref = prefs.getBool(_showHintTrailKey);
    final animatedBackgroundPref =
    prefs.getBool(_animatedBackgroundKey);
    final idleShimmerPref = prefs.getBool(_idleShimmerKey);
    final devUnlockPref = prefs.getBool(_devUnlockPremiumKey);
    final presetPref = prefs.getString(_activeCosmeticPresetKey);
    final enabledEffectsPref = prefs.getString(_enabledEffectsKey);

    if (colorValue != null) {
      _tileColor = Color(colorValue);
    }
    if (borderColorValue != null) {
      _borderColor = Color(borderColorValue);
    }
    if (borderStyleId != null) {
      final resolved = TileBorderStyles.tryById(borderStyleId);
      if (resolved != null) {
        _borderStyleId = resolved.id;
      } else {
        _borderStyleId = TileBorderStyles.defaultStyle.id;
        await prefs.setString(_borderStyleKey, _borderStyleId);
      }
    } else {
      final legacyPath = prefs.getString(_borderAssetPathKey);
      _borderStyleId = TileBorderStyles.migrateLegacyAssetPath(legacyPath);
      await prefs.setString(_borderStyleKey, _borderStyleId);
    }
    if (!prefs.containsKey(_borderColorKey)) {
      _borderColor = _tileColor;
      await prefs.setInt(_borderColorKey, _borderColor.value);
    }
    if (boardStyleId != null) {
      final resolved = BoardStyles.tryById(boardStyleId);
      if (resolved != null) {
        _boardStyleId = resolved.id;
      } else {
        _boardStyleId = BoardStyles.defaultStyle.id;
        await prefs.setString(_boardStyleKey, _boardStyleId);
      }
    } else {
      _boardStyleId = BoardStyles.defaultStyle.id;
      await prefs.setString(_boardStyleKey, _boardStyleId);
    }
    if (tileAnimationStyleId != null) {
      final resolved = TileAnimationStyles.tryById(tileAnimationStyleId);
      if (resolved != null) {
        _tileAnimationStyleId = resolved.id;
      } else {
        _tileAnimationStyleId = TileAnimationStyles.defaultStyle.id;
      }
    } else {
      _tileAnimationStyleId = TileAnimationStyles.defaultStyle.id;
    }
    await prefs.setString(_tileAnimationStyleKey, _tileAnimationStyleId);
    await prefs.remove(_borderAssetPathKey);

    if (soundEnabled != null) {
      _soundEnabled = soundEnabled;
    } else {
      await prefs.setBool(_soundEnabledKey, _soundEnabled);
    }

    if (hapticsEnabled != null) {
      _hapticsEnabled = hapticsEnabled;
    } else {
      await prefs.setBool(_hapticsEnabledKey, _hapticsEnabled);
    }


    if (titleCasePref != null) {
      _useTitleCaseWords = titleCasePref;
    } else {
      await prefs.setBool(_titleCaseKey, _useTitleCaseWords);
    }

    if (soundPackPref != null && soundPackPref.isNotEmpty) {
      _soundPack = soundPackPref;
    } else {
      await prefs.setString(_soundPackKey, _soundPack);
    }

    if (moveIntensityPref != null) {
      _moveHapticIntensity = MoveHapticIntensity.values.firstWhere(
            (value) => value.name == moveIntensityPref,
        orElse: () => MoveHapticIntensity.light,
      );
    } else {
      await prefs.setString(
        _moveHapticIntensityKey,
        _moveHapticIntensity.name,
      );
    }

    if (successIntensityPref != null) {
      _successHapticIntensity = SuccessHapticIntensity.values.firstWhere(
            (value) => value.name == successIntensityPref,
        orElse: () => SuccessHapticIntensity.medium,
      );
    } else {
      await prefs.setString(
        _successHapticIntensityKey,
        _successHapticIntensity.name,
      );
    }

    if (hintEffectPref != null && hintEffectPref.isNotEmpty) {
      _hintEffect = hintEffectPref.startsWith('hint.')
          ? hintEffectPref
          : 'hint.inner_pulse';
    } else {
      await prefs.setString(_hintEffectKey, _hintEffect);
    }

    if (hintTrailPref != null) {
      _showHintTrail = hintTrailPref;
    } else {
      await prefs.setBool(_showHintTrailKey, _showHintTrail);
    }

    if (animatedBackgroundPref != null) {
      _animatedBackground = animatedBackgroundPref;
    } else {
      await prefs.setBool(_animatedBackgroundKey, _animatedBackground);
    }

    if (idleShimmerPref != null) {
      _idleShimmer = idleShimmerPref;
    } else {
      await prefs.setBool(_idleShimmerKey, _idleShimmer);
    }

    if (devUnlockPref != null) {
      _devUnlockPremiumCosmetics = devUnlockPref;
    } else {
      await prefs.setBool(
        _devUnlockPremiumKey,
        _devUnlockPremiumCosmetics,
      );
    }

    if (presetPref != null && presetPref.isNotEmpty) {
      _activePresetId = presetPref;
    } else {
      _activePresetId = 'preset.classic';
      await prefs.setString(_activeCosmeticPresetKey, _activePresetId);
    }

    if (enabledEffectsPref != null && enabledEffectsPref.isNotEmpty) {
      final Map<String, dynamic> decoded =
      jsonDecode(enabledEffectsPref) as Map<String, dynamic>;
      _enabledEffects = _baselineEffectFlags.map(
            (key, value) => MapEntry(
          key,
          decoded.containsKey(key) ? decoded[key] == true : value,
        ),
      );
    } else {
      _enabledEffects = Map<String, bool>.from(_baselineEffectFlags);
      await prefs.setString(
        _enabledEffectsKey,
        jsonEncode(_enabledEffects),
      );
    }
    notifyListeners();
  }

  /// Persists a new [color] for puzzle tiles.
  Future<void> updateTileColor(Color color) async {
    _tileColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tileColorKey, color.value);
    notifyListeners();
  }

  /// Persists a new border [color] for puzzle tiles.
  Future<void> updateBorderColor(Color color) async {
    _borderColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_borderColorKey, color.value);
    notifyListeners();
  }

  /// Persists a new border [style].
  Future<void> updateBorderStyle(
      TileBorderStyle style, {
        bool allowPremium = false,
      }) async {
    if (style.isPremium && !allowPremium) {
      throw StateError('Attempted to select premium style without access.');
    }
    _borderStyleId = style.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_borderStyleKey, style.id);
    notifyListeners();
  }

  /// Persists a new board [style].
  Future<void> updateBoardStyle(
      BoardStyle style, {
        bool allowPremium = false,
      }) async {
    if (style.isPremium && !allowPremium) {
      throw StateError('Attempted to select premium board without access.');
    }
    _boardStyleId = style.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_boardStyleKey, style.id);
    notifyListeners();
  }

  /// Persists a new tile animation [style].
  Future<void> updateTileAnimationStyle(
      TileAnimationStyle style, {
        bool allowPremium = false,
      }) async {
    if (style.isPremium && !allowPremium) {
      throw StateError(
        'Attempted to select premium tile animation without access.',
      );
    }
    _tileAnimationStyleId = style.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tileAnimationStyleKey, style.id);
    notifyListeners();
  }

  Future<void> updateSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, value);
    notifyListeners();
  }

  Future<void> updateHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, value);
    notifyListeners();
  }

  Future<void> updateSoundPack(String soundPack) async {
    _soundPack = soundPack;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundPackKey, soundPack);
    notifyListeners();
  }

  Future<void> updateMoveHapticIntensity(MoveHapticIntensity value) async {
    _moveHapticIntensity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_moveHapticIntensityKey, value.name);
    notifyListeners();
  }

  Future<void> updateSuccessHapticIntensity(
      SuccessHapticIntensity value,
      ) async {
    _successHapticIntensity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_successHapticIntensityKey, value.name);
    notifyListeners();
  }

  Future<void> updateHintEffect(String value) async {
    _hintEffect = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hintEffectKey, value);
    notifyListeners();
  }

  Future<void> updateShowHintTrail(bool value) async {
    _showHintTrail = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showHintTrailKey, value);
    notifyListeners();
  }

  Future<void> updateAnimatedBackgroundEnabled(bool value) async {
    _animatedBackground = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animatedBackgroundKey, value);
    notifyListeners();
  }

  Future<void> updateIdleShimmerEnabled(bool value) async {
    _idleShimmer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_idleShimmerKey, value);
    notifyListeners();
  }

  Future<void> updateDevUnlockPremiumCosmetics(bool value) async {
    _devUnlockPremiumCosmetics = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devUnlockPremiumKey, value);
    notifyListeners();
  }

  Future<void> updateUseTitleCaseWords(bool value) async {
    _useTitleCaseWords = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_titleCaseKey, value);
    notifyListeners();
  }

  Future<void> persistCosmeticConfig({
    required String presetId,
    required Map<String, bool> enabledEffects,
  }) async {
    _activePresetId = presetId;
    _enabledEffects = _baselineEffectFlags.map(
          (key, value) => MapEntry(key, enabledEffects[key] ?? value),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeCosmeticPresetKey, _activePresetId);
    await prefs.setString(
      _enabledEffectsKey,
      jsonEncode(_enabledEffects),
    );
    notifyListeners();
  }
}