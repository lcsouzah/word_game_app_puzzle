//Y:\word_game_app_puzzle\lib\utils\category_unlock_manager.dart

import 'package:shared_preferences/shared_preferences.dart';


class CategoryUnlockManager{
  // check if a category is unlock
  static Future<bool> isCategoryUnlocked(String categoryKey) async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('unlocked_$categoryKey') ?? false;
  }

  //unlock a category
  static Future<void> unlockCategory(String categoryKey) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('unlocked_$categoryKey', true);
  }
}