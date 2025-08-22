//Y:\word_game_app_puzzle\lib\utils\category_unlock_manager.dart

import 'package:shared_preferences/shared_preferences.dart';


class CategoryUnlockManager {
  static String _normalizeKey(String key) =>
      key.toLowerCase().replaceAll(' ', '_');

  // check if a category is unlock
  static Future<bool> isCategoryUnlocked(String categoryKey) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedKey = _normalizeKey(categoryKey);
    return prefs.getBool('unlocked_$normalizedKey') ?? false;
  }

  //unlock a category
  static Future<void> unlockCategory(String categoryKey) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedKey = _normalizeKey(categoryKey);
    await prefs.setBool('unlocked_$normalizedKey', true);
  }
}