import 'package:flutter/foundation.dart';

/// Provides reactive access to cosmetic selections applied throughout the
/// puzzle experience. The manager exposes lightweight string identifiers so
/// UI code can map them to themed assets or colours.
class CosmeticManager extends ChangeNotifier {
  String boardSkin = 'classic';
  String tileSkin = 'default';
  String soundPack = 'classic';
  String trailEffect = 'sparkle';

  void setSkin(String type, String name) {
    switch (type) {
      case 'board':
        if (boardSkin == name) return;
        boardSkin = name;
        break;
      case 'tile':
        if (tileSkin == name) return;
        tileSkin = name;
        break;
      case 'sound':
        if (soundPack == name) return;
        soundPack = name;
        break;
      case 'trail':
        if (trailEffect == name) return;
        trailEffect = name;
        break;
      default:
        return;
    }
    notifyListeners();
  }
}