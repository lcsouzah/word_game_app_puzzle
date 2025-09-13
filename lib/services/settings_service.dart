import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides persisted user settings for tile appearance.
///
/// The service stores the selected [tileColor] and [borderAssetPath]
/// using [SharedPreferences] so choices survive app restarts.
class SettingsService extends ChangeNotifier {
  static const _tileColorKey = 'tileColor';
  static const _borderAssetPathKey = 'borderAssetPath';

  Color _tileColor = Colors.blueGrey;
  String _borderAssetPath = '';

  /// Current color used for puzzle tiles.
  Color get tileColor => _tileColor;

  /// Optional asset path used as a tile border image.
  String get borderAssetPath => _borderAssetPath;

  /// Loads previously saved settings from [SharedPreferences].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_tileColorKey);
    final borderPath = prefs.getString(_borderAssetPathKey);
    if (colorValue != null) {
      _tileColor = Color(colorValue);
    }
    if (borderPath != null) {
      _borderAssetPath = borderPath;
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

  /// Persists a new border image asset [path].
  Future<void> updateBorderAssetPath(String path) async {
    _borderAssetPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_borderAssetPathKey, path);
    notifyListeners();
  }
}
