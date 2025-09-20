import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';

/// Provides persisted user settings for tile appearance.
///
/// The service stores the selected [tileColor] and [borderStyle]
/// using [SharedPreferences] so choices survive app restarts.
class SettingsService extends ChangeNotifier {
  static const _tileColorKey = 'tileColor';
  static const _borderStyleKey = 'borderStyle';
  static const _borderAssetPathKey = 'borderAssetPath';

  Color _tileColor = Colors.blueGrey;
  String _borderStyleId = TileBorderStyles.defaultStyle.id;

  /// Current color used for puzzle tiles.
  Color get tileColor => _tileColor;

  /// Currently selected border style.
  TileBorderStyle get borderStyle => TileBorderStyles.byId(_borderStyleId);

  /// Loads previously saved settings from [SharedPreferences].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_tileColorKey);
    final borderStyleId = prefs.getString(_borderStyleKey);
    if (colorValue != null) {
      _tileColor = Color(colorValue);
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
    await prefs.remove(_borderAssetPathKey);
    notifyListeners();
  }

  /// Persists a new [color] for puzzle tiles.
  Future<void> updateTileColor(Color color) async {
    _tileColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tileColorKey, color.value);
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
}
