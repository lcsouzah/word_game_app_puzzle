import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_game_app/word_slide/models/board_style.dart';
import 'package:word_game_app/word_slide/models/tile_animation_style.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';

/// Provides persisted user settings for tile appearance.
///
/// The service stores the selected [tileColor] and [borderStyle]
/// using [SharedPreferences] so choices survive app restarts.
class SettingsService extends ChangeNotifier {
  static const _tileColorKey = 'tileColor';
  static const _borderStyleKey = 'borderStyle';
  static const _borderColorKey = 'borderColor';
  static const _borderAssetPathKey = 'borderAssetPath';
  static const _boardStyleKey = 'boardStyle';
  static const _tileAnimationStyleKey = 'tileAnimationStyle';
  static const _soundEnabledKey = 'soundEnabled';
  static const _hapticsEnabledKey = 'hapticsEnabled';
  static const _titleCaseKey = 'titleCaseWOrds';

  Color _tileColor = Colors.blueGrey;
  Color _borderColor = Colors.blueGrey;
  String _borderStyleId = TileBorderStyles.defaultStyle.id;
  String _boardStyleId = BoardStyles.defaultStyle.id;
  String _tileAnimationStyleId = TileAnimationStyles.defaultStyle.id;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _useTitleCaseWords = true;


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
          'Attempted to select premium tile animation without access.');
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
  Future<void> updateUseTitleCaseWords(bool value) async {
    _useTitleCaseWords = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_titleCaseKey, value);
    notifyListeners();
  }
}